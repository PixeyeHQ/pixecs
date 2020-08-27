{.experimental: "dynamicBindSym".}
{.used.} 

import strutils
import macros
import ecs_h

var next_storage_id = 0

template px_ecs_storage(T: typedesc) {.used.} =
  var st_id   : int
  var st_indices : seq[int]
  var st_ents    : seq[eid]
  var st_comps   : seq[T]

 #private
  proc px_ecs_cleanup(_:typedesc[T]) = 
    st_ents.setLen(0); st_comps.setLen(0)
  
  proc px_ecs_release(_:typedesc[T],self: eid) =
    let last = st_indices[st_ents[st_ents.high].int]
    let index = st_indices[self.int]
    st_ents.del(index)
    st_comps.del(index)
    swap(st_indices[index],st_indices[last])
    st_indices[index] = int.high

  proc px_ecs_init(_:typedesc[T]) =
    st_id = next_storage_id;next_storage_id+=1
    st_ents    =  newSeqOfCap[eid](PX_ECS_DEFAULT_GROUP_SIZE)
    st_comps   =  newSeqOfCap[T](PX_ECS_DEFAULT_GROUP_SIZE)
    px_ecs_genindices(st_indices)
    px_ecs_meta_comp.add(CompStorageMeta())
   
    var m_st = px_ecs_meta_comp[px_ecs_meta_comp.high].addr
    m_st[].ents    = st_ents.addr
    m_st[].indices = st_indices.addr
    m_st[].groups  = newSeq[EcsGroup]()
    m_st[].actions = IStorage(cleanup: proc()=px_ecs_cleanup(T),remove: proc(self:eid)=px_ecs_release(T, self))
  
  proc px_ecs_get(self: ent|eid, _: typedesc[T]): ptr T {.inline, discardable, used.} =
    addr st_comps[st_indices[self.id]] 

  proc px_ecs_comps*(_:typedesc[T]): ptr seq[T] {.inline.} =
    st_comps.addr
  proc px_ecs_ents*(_:typedesc[T]): ptr seq[eid] {.inline.} =
    st_ents.addr

  proc px_ecs_id*(_:typedesc[T]): cid = st_id.cid

  proc has*(_:typedesc[T], self: eid): bool {.inline,discardable.} =
    st_indices[self.int] < st_ents.len
  
  proc get*(self: ent|eid, _:typedesc[T]): ptr T =
    if has(_,self):
      return st_comps[st_indices[self.id]].addr

    let len = st_ents.len
    st_indices[self.id] = len
    st_ents.add(self)
    
    px_ecs_meta[self.id].sig.add(st_id.cid)
    
    if not px_ecs_dirty:
      px_ecs_updGroups(self.id.eid,st_id.cid)

    st_comps.add(T())
    st_comps[len].addr
  
  proc remove*(self: ent|eid, _: typedesc[T]) =
    px_ecs_debug_remove(self, st_indices.addr, st_ents.addr,_)
    let last = st_indices[st_ents[st_ents.high].int]
    let index = st_indices[self.id]

    st_ents.del(index)
    st_comps.del(index)
    swap(st_indices[index],st_indices[last])
    
    let meta = self.meta
    meta.sig.del(meta.sig.find(st_id.cid))
    if meta.sig.len == 0:
      self.release()
    else:
      px_ecs_updGroups(self.id.eid,st_id.cid)
  
  px_ecs_init(T)

  px_ecs_format_getCompAlias(T)
  px_ecs_format_getCompAliasLong(T)

template px_ecs_storage_tag(T: typedesc) {.used.} =
  var st_id   : int
  var st_indices : seq[int]
  var st_ents    : seq[eid]
  var st_comps   : seq[T]

 #private
  proc px_ecs_cleanup(_:typedesc[T]) {.inline.} = 
    st_ents.setLen(0); st_comps.setLen(0)

  proc px_ecs_release(_:typedesc[T],self: eid) =
    let last = st_indices[st_ents[st_ents.high].int]
    let index = st_indices[self.id]

    st_ents.del(index)
    st_comps.del(index)
    swap(st_indices[index],st_indices[last])
  
  proc px_ecs_init(_:typedesc[T]) =
    st_id = next_storage_id;next_storage_id+=1
    st_ents    =  newSeqOfCap[eid](PX_ECS_DEFAULT_GROUP_SIZE)
    st_comps   =  newSeqOfCap[T](PX_ECS_DEFAULT_GROUP_SIZE)
    px_ecs_genindices(st_indices)
    px_ecs_meta_comp.add(CompStorageMeta())
   
    var m_st = px_ecs_meta_comp[px_ecs_meta_comp.high].addr
    m_st[].ents    = st_ents.addr
    m_st[].indices = st_indices.addr
    m_st[].groups  = newSeq[EcsGroup]()
    m_st[].actions = IStorage(cleanup: proc()=px_ecs_cleanup(T),remove: proc(self:eid)=px_ecs_release(T, self))

  proc px_ecs_get(self: ent|eid, _: typedesc[T]): int {.inline, discardable, used.} =
    st_comps[st_indices[self.id]].int
  
 #api

  proc px_ecs_id*(_:typedesc[T]): cid = st_id.cid
  
  proc has*(_:typedesc[T], self: eid): bool {.inline,discardable.} =
    st_indices[self.int] < st_ents.len
  
  proc remove*(self: ent|eid, _: typedesc[T]) =
    px_ecs_debug_remove(self, st_indices.addr, st_ents.addr,_)

    let last = st_indices[st_ents[st_ents.high].int]
    let index = st_indices[self.id]
    
    st_ents.del(index)
    st_comps.del(index)
    swap(st_indices[index],st_indices[last])

    let meta = self.meta
    meta.sig.del(meta.sig.find(st_id.cid))
    if meta.sig.len == 0:
      self.release()
    else:
      px_ecs_updGroups(self.id.eid,st_id.cid)
  
  proc inc*(self: ent|eid, _:typedesc[T], arg: int = 1)  =
    if has(_,self):
      let temp =  st_comps[st_indices[self.id]].int + arg
      st_comps[st_indices[self.id]] = temp.T
    
    let len = st_ents.len
    st_indices[self.id] = len
    st_ents.add(self)
    
    px_ecs_meta[self.id].sig.add(st_id.cid)


    if not px_ecs_dirty:
      px_ecs_updGroups(self.id.eid,st_id.cid)

    st_comps.add(arg.T)
  
  proc dec*(self: ent|eid, _:typedesc[T], arg: int = 1)  =
    if not has(_,self): return

    let temp =  st_comps[st_indices[self.id]].int - arg
    
    if temp <= 0:
      remove(self, T)
    else:
      st_comps[st_indices[self.id]] = temp.T

  px_ecs_init(T)

  px_ecs_format_tags(T)

iterator ecsQuery*(E: typedesc[Ent], T: typedesc): (eid, ptr T) =
  let st_comps = T.px_ecs_comps
  let st_ents =  T.px_ecs_ents
  for i in countdown(st_comps[].high,0):
    yield (st_ents[][i], st_comps[][i].addr)

iterator ecsQuery*(T: typedesc): ptr T=
  let st_comps = T.px_ecs_comps
  for i in countdown(st_comps[].high,0):
    yield st_comps[][i].addr

iterator ecsQuere*(T: typedesc): eid =
  let st_ents =  T.px_ecs_ents
  for i in countdown(st_ents[].high,0):
    yield st_ents[i]

macro ecsAdd*(component: untyped, mode: static[CompType] = CompType.AsComp): untyped =
  let node_storage = nnkCommand.newTree()

  if mode == CompType.AsComp:
    node_storage.insert(0,bindSym("px_ecs_storage", brForceOpen))
    node_storage.insert(1,newIdentNode($component))
  else:
    node_storage.insert(0,bindSym("px_ecs_storage_tag", brForceOpen))
    node_storage.insert(1,newIdentNode($component))

  result = nnkStmtList.newTree(
          node_storage
          )
  var name_alias = $component
  if (name_alias.contains("Component") or name_alias.contains("Comp")):
      px_ecs_format_comp_alias(name_alias)
      
      let node = nnkTypeSection.newTree(
      nnkTypeDef.newTree(
          nnkPostfix.newTree(
              newIdentNode("*"),
              newIdentNode(name_alias)),
              newEmptyNode(),
      newIdentNode($component)
      ))
      result.add(node)

