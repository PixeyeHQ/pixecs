{.experimental: "dynamicBindSym".}
{.used.} 

import strutils
import macros
import strformat
import ecs_h



template impl_storage*(T: typedesc) {.used.} =
  var st_id = next_storage_id; next_storage_id += 1
  var st_ents = newSeqOfCap[eid]((AMOUNT_ENTS/2).int)
  # var st_indices : seq[int]
  # var st_ents    : seq[eid]
  # var st_comps   : seq[T]

#  #private
#   proc cleanup(_:typedesc[T]) = 
#     st_ents.setLen(0); st_comps.setLen(0)
  
#   proc removeOnRelease(_:typedesc[T],self: eid) =
#     let last = st_indices[st_ents[st_ents.high].int]
#     let index = st_indices[self.int]
#     st_ents.del(index)
#     st_comps.del(index)
#     swap(st_indices[index],st_indices[last])
#     st_indices[index] = int.high

#   proc init(_:typedesc[T]) =
#     st_id = next_storage_id;next_storage_id+=1
#     st_ents    =  newSeqOfCap[eid]((AMOUNT_ENTS/2).int)
#     st_comps   =  newSeqOfCap[T]((AMOUNT_ENTS/2).int)
#     init_indices(st_indices)
#     metas_storage.add(CompStorageMeta())
   
#     var m_st = metas_storage[metas_storage.high].addr
#     m_st[].ents    = st_ents.addr
#     m_st[].indices = st_indices.addr
#     m_st[].groups  = newSeq[EcsGroup]()
#     m_st[].actions = IStorage(cleanup: proc()=cleanup(T),remove: proc(self:eid)=removeOnRelease(T, self))

#   proc impl_get(self: ent|eid, _: typedesc[T]): ptr T {.inline, discardable, used.} =
#     addr st_comps[st_indices[self.id]] 
  
#  #api

#   iterator query*(ecs:Ecs, E: typedesc[Ent], _: typedesc[T]): (eid, ptr T) =
#     for i in countdown(st_comps.high,0):
#       yield (st_ents[i], st_comps[i].addr)
#   iterator quere*(ecs:Ecs, _: typedesc[T]): eid =
#     for i in countdown(st_comps.high,0):
#       yield st_ents[i]
#   iterator query*(ecs:Ecs, _: typedesc[T]): ptr T =
#     for i in countdown(st_comps.high,0):
#        yield st_comps[i].addr
 
#   proc getId*(_:typedesc[T]): cid = st_id.cid
  
#   proc getComps*(_:typedesc[T]): ptr seq[T] =
#     st_comps.addr
  
#   proc has*(_:typedesc[T], self: eid): bool {.inline,discardable.} =
#     st_indices[self.int] < st_ents.len
  
#   proc get*(self: ent|eid, _:typedesc[T]): ptr T =
#     if has(_,self):
#       return st_comps[st_indices[self.id]].addr

#     let len = st_ents.len
#     st_indices[self.id] = len
#     st_ents.add(self)
    
#     metas[self.id].sig.add(st_id.cid)
    
#     if not ecs.dirty:
#       updateGroups(self.id.eid,st_id.cid)

#     st_comps.add(T())
#     st_comps[len].addr
  
#   proc remove*(self: ent|eid, _: typedesc[T]) =
#     let last = st_indices[st_ents[st_ents.high].int]
#     let index = st_indices[self.id]

#     st_ents.del(index)
#     st_comps.del(index)
#     swap(st_indices[index],st_indices[last])
    
#     let meta = self.meta
#     meta.sig.del(meta.sig.find(st_id.cid))
#     if meta.sig.len == 0:
#       self.release()
#     else:
#       updateGroups(self.id.eid,st_id.cid)
  
#   init(T)

#   formatComponentPretty(T)
#   formatComponentPrettyAndLong(T)

template impl_storage_tag*(T: typedesc) {.used.} =
  var st_id   : int
  var st_indices : seq[int]
  var st_ents    : seq[eid]
  var st_comps   : seq[T]

 #private
  proc cleanup(_:typedesc[T]) {.inline.} = 
    st_ents.setLen(0); st_comps.setLen(0)

  proc removeOnRelease(_:typedesc[T],self: eid) =
    let last = st_indices[st_ents[st_ents.high].int]
    let index = st_indices[self.id]

    st_ents.del(index)
    st_comps.del(index)
    swap(st_indices[index],st_indices[last])
  
  proc init(_:typedesc[T]) =
    st_id = next_storage_id;next_storage_id+=1
    st_ents    =  newSeqOfCap[eid]((AMOUNT_ENTS/2).int)
    st_comps   =  newSeqOfCap[T]((AMOUNT_ENTS/2).int)
    init_indices(st_indices)
    metas_storage.add(CompStorageMeta())
   
    var m_st = metas_storage[metas_storage.high].addr
    m_st[].ents    = st_ents.addr
    m_st[].indices = st_indices.addr
    m_st[].groups  = newSeq[EcsGroup]()
    m_st[].actions = IStorage(cleanup: proc()=cleanup(T),remove: proc(self:eid)=removeOnRelease(T, self))


  proc impl_get(self: ent|eid, _: typedesc[T]): int {.inline, discardable, used.} =
    st_comps[st_indices[self.id]].int
  
 #api

  iterator query*(ecs:Ecs, E: typedesc[Ent], _: typedesc[T]): (eid, ptr T) =
    for i in countdown(st_comps.high,0):
      yield (st_ents[i], st_comps[i].addr)
  iterator quere*(ecs:Ecs, E: typedesc[Ent], _: typedesc[T]): eid =
    for i in countdown(st_comps.high,0):
      yield st_ents[i]
  iterator query*(ecs:Ecs, _: typedesc[T]): ptr T =
    for i in countdown(st_comps.high,0):
       yield st_comps[i].addr
 
  proc getId*(_:typedesc[T]): cid = st_id.cid
  
  proc getComps*(_:typedesc[T]): ptr seq[T] {.inline.} =
    st_comps.addr
  
  proc has*(_:typedesc[T], self: eid): bool {.inline,discardable.} =
    st_indices[self.int] < st_ents.len
  
  proc remove*(self: ent|eid, _: typedesc[T]) =
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
      updateGroups(self.id.eid,st_id.cid)
  
  proc inc*(self: ent|eid, _:typedesc[T], arg: int = 1)  =
    if has(_,self):
      let temp =  st_comps[st_indices[self.id]].int + arg
      st_comps[st_indices[self.id]] = temp.T
    
    let len = st_ents.len
    st_indices[self.id] = len
    st_ents.add(self)
    
    self.meta.sig.add(st_id.cid)
    
    if not ecs.dirty:
      updateGroups(self.id.eid,st_id.cid)

    st_comps.add(arg.T)
  
  proc dec*(self: ent|eid, _:typedesc[T], arg: int = 1)  =
    if not has(_,self): return


    let temp =  st_comps[st_indices[self.id]].int - arg
    
    if temp <= 0:
      remove(self, T)
    else:
      st_comps[st_indices[self.id]] = temp.T

  init(T)

  formatTagPrettyAndLong(T)

macro add*(ecs: Ecs, component: untyped, mode: static[CompType] = CompType.AsComp): untyped =
  
  let node_storage = nnkCommand.newTree()

  if mode == CompType.AsComp:
    node_storage.insert(0,bindSym("impl_storage", brForceOpen))
    node_storage.insert(1,newIdentNode($component))
  else:
    node_storage.insert(0,bindSym("impl_storage_tag", brForceOpen))
    node_storage.insert(1,newIdentNode($component))

  
  result = nnkStmtList.newTree(
          node_storage
          )
  var name_alias = $component
  if (name_alias.contains("Component") or name_alias.contains("Comp")):
      formatComponentAlias(name_alias)
      
      let node = nnkTypeSection.newTree(
      nnkTypeDef.newTree(
          nnkPostfix.newTree(
              newIdentNode("*"),
              newIdentNode(name_alias)),
              newEmptyNode(),
      newIdentNode($component)
      ))
      result.add(node)

macro formatTagPrettyAndLong*(T: typedesc): untyped {.used.}=
  let tName = strVal(T)
  var proc_name = tName  
  proc_name  = toLowerAscii(proc_name[0]) & substr(proc_name, 1)
  formatComponent(proc_name)
  var source = &("""
  template `{proc_name}`*(self: ent|eid): int =
      impl_get(self,{tName})
      """)
  result = parseStmt(source)

macro formatComponentPrettyAndLong*(T: typedesc): untyped {.used.}=
  let tName = strVal(T)
  var proc_name = tName  
  proc_name  = toLowerAscii(proc_name[0]) & substr(proc_name, 1)
  formatComponent(proc_name)
  var source = &("""
  template `{proc_name}`*(self: ent|eid): ptr {tName} =
      impl_get(self,{tName})
      """)
  result = parseStmt(source)

macro formatComponentPretty*(t: typedesc): untyped {.used.}=
  let tName = strVal(t)
  var proc_name = tName  
  formatComponent(proc_name)
  var source = ""
  source = &("""
    template `{proc_name}`*(self: ent|eid): ptr {tName} =
        impl_get(self,{tName})
        """)

  result = parseStmt(source)



dumpTree:
  var st_id = next_storage_id
  var st_ents = newSeqOfCap[eid]((AMOUNT_ENTS/2).int)
  #var st_id      : int
  # var st_indices : seq[int]
  # var st_ents    : seq[eid]
  # var st_compa   : seq[CompA]
  # iterator query*(ecs:Ecs, _: typedesc[CompA]): ptr CompA =
  #    var x = stCompA.high
  #    while x > -1:
  #      yield stCompA[x].addr
  #      x -= 1

template genEcsIdentDefs(): untyped =
  nnkIdentDefs.newTree(ident("ecs"),ident("Ecs"),newEmptyNode())
template genTypeIdentDefs(T: untyped): untyped =
  nnkIdentDefs.newTree(ident("_"), nnkBracketExpr.newTree(ident("typedesc"),ident(&"{T}")),newEmptyNode())
template nEmpty(): untyped =
  newEmptyNode()
template varDef(arg: untyped, t: untyped): untyped =
  let n = nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      ident(arg),
      ident($t),
      nEmpty()
    )
  )
  n
template varDefBracket(arg: untyped, t: untyped, t2: untyped): untyped =
  let n = nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      ident(arg),
      nnkBracketExpr.newTree(
        ident($t),
        ident($t2)
      )
      ,nEmpty()
    )
  )
  n
template varSet(arg: untyped, t: untyped): untyped =
  let n = nnkVarSection.newTree(
    nnkIdentDefs.newTree(
      ident(arg),
      nempty(),
      ident(t)))
  n

macro buildComp*(T:untyped, size: static int): untyped =
  let n = newStmtList()
  var t_name = toLowerAscii(&"st_{T}")
  var t_id = toLowerAscii(&"{t_name}_id")
  var t_indices = toLowerAscii(&"{t_name}_indices")
  var t_ents = toLowerAscii(&"{t_name}_ents")

  var n1 = varSet(t_id,"next_storage_id")
  var n1_2 = nnkInfix.newTree(ident("+="),ident("next_storage_id"),newIntLitNode(1))
  
  var n2 = nnkVarSection.newtree(
    nnkIdentDefs.newtree(
      ident(t_ents),
      nempty(),
      nnkCall.newtree(
        nnkBracketExpr.newtree(
          ident("newSeqOfCap"),
          ident("eid")
        ),
        nnkDotExpr.newtree(
          nnkPar.newtree(
            nnkInfix.newtree(
              ident("/"),
              ident("AMOUNT_ENTS"),
              newIntLitNode(2)
            )),
            ident("int")
        )
      )
    )
  )
  #var n2 =nn
  #var n2 =
  #var n_3 = 
  # build storage
  # let n1 = nnkVarSection.newTree(
  #   nnkIdentDefs.newTree(
  #     ident(tname),
  #     newEmptyNode(),
  #     newCall(nnkBracketExpr.newTree(ident("newSeq"),ident(&"{T}")),newIntLitNode(size))))
  
  #let n1 = varDef(t_id,int)
  #let n2 = varDefBracket(tname,seq,T)
  #let n3 = varDefBracket(t_indices,seq,int)
  #let n4 = varDefBracket(t_ents,seq,eid)

  # build storageGetter
  let n5 = nnkProcDef.newTree(
    nnkPostfix.newTree(
      ident("*"),
      ident(&"get{T}")
    ),
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      nnkPtrTy.newTree(
        ident(&"{T}")
      ),
      nnkIdentDefs.newTree(
        ident("i"),
        ident("int"),
        newEmptyNode()
      )
    ),
      newEmptyNode(),
      newEmptyNode(),
      nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkBracketExpr.newTree(
            ident(&"st{T}"),
            ident("i")
          ),
          ident("addr")
        )
      )
      )
  # build query
  let n6 = nnkIteratorDef.newTree(
    nnkPostfix.newTree(
      ident("*"),
      ident("query")
    ),
    nEmpty,
    nEmpty,
    nnkFormalParams.newTree(
      nnkPtrTy.newTree(ident(&"{T}")),
      genEcsIdentDefs(),
      genTypeIdentDefs(T)
    ),
    nEmpty,
    nEmpty,
    nnkStmtList.newTree(
      nnkVarSection.newTree(
        nnkIdentDefs.newTree(ident("x"),nEmpty,nnkDotExpr.newTree(ident(tname),ident("high")))
      ),
      nnkWhileStmt.newTree(
        nnkInfix.newTree(ident(">"),ident("x"),nnkPrefix.newTree(ident("-"),newIntLitNode(1))),
        nnkStmtList.newTree(
          nnkYieldStmt.newTree(
            nnkDotExpr.newTree(nnkBracketExpr.newTree(ident(tname),ident("x")),ident("addr"))),
          nnkInfix.newTree(ident("-="),ident("x"),newIntLitNode(1))
        )
      )
    )
  )
  
  var next : int = 0
  n.insert(next,n1);  next.inc
  n.insert(next,n1_2); next.inc
  n.insert(next,n2)
  #n.insert(1,n2)
 # n.insert(2,n3)
 # n.insert(3,n4)


  # n.insert(1,n2)
  # n.insert(2,n3)

  result = n