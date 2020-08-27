{.used.}
{.experimental: "dynamicBindSym".}

import macros
import sets
import algorithm
import hashes
import ecs_h

var incl_sig  : set[cid]
var excl_sig  : set[cid]

proc partof*(self: ent|eid, group: EcsGroup): bool =
  group.indices[self.id] < group.ents.len

proc match*(self: ent|eid, group: EcsGroup):  bool =
  for i in group.incl_sig:
    let m_st = px_ecs_meta_comp[i]
    if m_st.indices[][self.id] > m_st.ents[].high: # if has no comp
      return false
  for i in group.excl_sig:
    let m_st = px_ecs_meta_comp[i]
    if m_st.indices[][self.id] < m_st.ents[].len: # if has comp
      return false
  true

proc px_ecs_insert*(gr: EcsGroup, self: eid) {.inline.} = 
  let len = gr.ents.len
  gr.indices[self.id] = len
  gr.ents.add(self)
  px_ecs_meta[self.int].sig_groups.add(gr.id)

proc px_ecs_remove*(gr: EcsGroup, self: eid) {.inline.} =
  let meta = px_ecs_meta[self.int].addr
  let last = gr.indices[gr.ents[gr.ents.high].int]
  let index = gr.indices[self.id]
  gr.ents.del(index)
  swap(gr.indices[index],gr.indices[last])
  meta.sig_groups.del(meta.sig_groups.find(gr.id))

proc px_ecs_initGroup() : EcsGroup {.inline, used, discardable.} =
  var id_next_group {.global.} : cid = 0
  var group_next : EcsGroup = nil
  
  let incl_hash = incl_sig.hash
  let excl_hash = excl_sig.hash
  
  func sort_storages(x,y: CompStorageMeta): int =
    let cx = x.ents
    let cy = y.ents
    if cx[].len <= cy[].len: -1
    else: 1

  proc addGroup(): var EcsGroup =
    px_ecs_groups.add(EcsGroup())
    px_ecs_groups[px_ecs_groups.high]
  
  for i in 0..px_ecs_groups.high:
    let gr = px_ecs_groups[i]
    if gr.incl_hash == incl_hash and
      gr.excl_hash == excl_hash:
         group_next = gr; break

  if group_next.isNil:
    group_next = addGroup()
    group_next.id = id_next_group
    group_next.ents = newSeqOfCap[eid](PX_ECS_DEFAULT_GROUP_SIZE)
    group_next.incl_hash = incl_hash
    group_next.excl_hash = excl_hash
    px_ecs_genindices(group_next.indices)
    var storage_owner = newSeq[CompStorageMeta]()
    
    for id in incl_sig:
      group_next.incl_sig.add(id)
      px_ecs_meta_comp[id].groups.add(group_next)
      storage_owner.add(px_ecs_meta_comp[id])
    for id in excl_sig:
      group_next.excl_sig.add(id)
      px_ecs_meta_comp[id].groups.add(group_next)
   
    storage_owner.sort(sortStorages)

    for i in storage_owner[0][].ents[]:
      if match(i,group_next):
        px_ecs_insert(group_next,i)

    id_next_group += 1
  
  incl_sig = {}
  excl_sig = {}
  group_next

proc px_ecs_updgroups*(self: eid, cid: uint16) {.inline.} =
  let groups = px_ecs_meta_comp[cid].groups
  for group in groups:
    let grouped = self.partof(group)
    let matched = self.match(group)
    if grouped and not matched:
      px_ecs_remove(group,self)
    elif not grouped and matched:
      px_ecs_insert(group,self)

template ecsGroup*(t: varargs[untyped]): EcsGroup =
  var group_cached {.global.} : EcsGroup
  if group_cached.isNil:
    group_cached = px_ecs_genGroup(t)
  group_cached

iterator items*(range: EcsGroup): eid =
  for i in countdown(range.ents.high,0):
    yield range.ents[i]

template len*(self: EcsGroup): int =
  self.ents.len

template high*(self: EcsGroup): int =
  self.ents.high

template `[]`*(self: EcsGroup, key: int): ent =
  self.ents[key]

proc `bind`*(self: ent|eid) {.inline.} =
  px_ecs_dirty = false
  let meta = px_ecs_meta[self.id]
  for cid in meta.sig:
    let groups = px_ecs_meta_comp[cid].groups
    for group in groups:
      if not self.partof(group) and self.match(group):
        px_ecs_insert(group,self)

macro px_ecs_genGroup*(t: varargs[untyped]) =
  var n = newNimNode(nnkStmtList)
  template genMask(arg: untyped): NimNode =
    var n = newNimNode(nnkCall)
    if arg.len > 0 and $arg[0] == "!":
      n.insert(0,newDotExpr(bindSym("excl_sig"), ident("incl")))
      n.insert(1,newDotExpr(ident($arg[1]), ident("px_ecs_id")))
    else:
      n.insert(0,newDotExpr(bindSym("incl_sig") , ident("incl")))
      n.insert(1,newDotExpr(ident($arg), ident("px_ecs_id")))
    n
  var i = 0
  for x in t.children:
    n.insert(i,genMask(x))
    i += 1
  n.insert(i,newCall(bindSym("px_ecs_initGroup",brForceOpen)))
  result = n
