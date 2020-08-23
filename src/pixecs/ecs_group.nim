{.used.}
{.experimental: "dynamicBindSym".}

import macros
import sets
import algorithm
import hashes
import ecs_h

var incl_sig  : set[cid]
var excl_sig  : set[cid]


func sort_storages(x,y: CompStorageMeta): int =
  let cx = x.ents
  let cy = y.ents
  if cx[].len <= cy[].len: -1
  else: 1
func binarysearch*(this: ptr seq[eid], value: int): int {.discardable, used, inline.} =
  var m : int = -1
  var left = 0
  var right = this[].high
  while left <= right:
      m = (left+right) div 2
      if this[][m].int == value: 
          return m
      if this[][m].int < value:
          left = m + 1
      else:
          right = m - 1
  return m

macro init_group*(t: varargs[untyped]) =
  var n = newNimNode(nnkStmtList)
  template genMask(arg: untyped): NimNode =
    var n = newNimNode(nnkCall)
    if arg.len > 0 and $arg[0] == "!":
      n.insert(0,newDotExpr(bindSym("excl_sig"), ident("incl")))
      n.insert(1,newDotExpr(ident($arg[1]), ident("getId")))
    else:
      n.insert(0,newDotExpr(bindSym("incl_sig") , ident("incl")))
      n.insert(1,newDotExpr(ident($arg), ident("getId")))
    n
  var i = 0
  for x in t.children:
    n.insert(i,genMask(x))
    i += 1
  n.insert(i,newDotExpr(ident("ecs"),bindSym("make_group",brForceOpen)))
  result = n


proc partof*(self: ent|eid, group: EcsGroup): bool =
  group.indices[self.id] < group.ents.len

# proc partof*(self: ent|eid, group: EcsGroup): bool =
#   if group.id in self.meta.sig_groups:
#     true
#   else: false

proc match*(self: ent|eid, group: EcsGroup):  bool =
  for i in group.incl_sig:
    let m_st = metas_storage[i]
    if m_st.indices[][self.id] > m_st.ents[].high: # if has no comp
      return false
  for i in group.excl_sig:
    let m_st = metas_storage[i]
    if m_st.indices[][self.id] < m_st.ents[].len: # if has comp
      return false
  true
proc insert*(gr: EcsGroup, self: eid) {.inline.} = 
  let len = gr.ents.len
  gr.indices[self.id] = len
  gr.ents.add(self)
  metas[self.int].sig_groups.add(gr.id)

# proc insert*(gr: EcsGroup, self: eid) {.inline.} = 
#   var len = gr.ents.len
#   var left, index = 0
#   var right = len
#   len+=1
#   var conditionSort = right - 1
#   if conditionSort > -1 and self.int < gr.ents[conditionSort].int:
#       while right > left:
#           var midIndex = (right+left) div 2
#           if gr.ents[midIndex].int == self.int:
#               index = midIndex
#               break
#           if gr.ents[midIndex].int < self.int:
#               left = midIndex+1
#           else:
#               right = midIndex
#           index = left
#       gr.ents.insert(self, index)
#   else:
#       if right == 0 or right >= gr.ents.high:
#           gr.ents.add self
#       else:
#           gr.ents[right] = self

#   metas[self.int].sig_groups.add(gr.id)

proc remove*(gr: EcsGroup, self: eid) {.inline.} =
  let meta = metas[self.int].addr
  let last = gr.indices[gr.ents[gr.ents.high].int]
  let index = gr.indices[self.id]
  gr.ents.del(index)
  swap(gr.indices[index],gr.indices[last])
  meta.sig_groups.del(meta.sig_groups.find(gr.id))

# proc remove*(gr: EcsGroup, self: eid) {.inline.} =
#   let meta = metas[self.int].addr
#   let index = binarysearch(addr gr.ents, self.int)
#   gr.ents.delete(index)
#   meta.sig_groups.del(meta.sig_groups.find(gr.id))



proc tryinsert*(gr: EcsGroup, eids: ptr seq[eid]) {.inline.} =
  for i in eids[]:
    if match(i,gr):
      gr.insert(i)

proc make_group(ecs: Ecs) : EcsGroup {.inline, used, discardable.} =
  var id_next_group {.global.} : cid = 0
  var group_next : EcsGroup = nil
  
  let incl_hash = incl_sig.hash
  let excl_hash = excl_sig.hash
  
  proc addGroup(): var EcsGroup =
    groups.add(EcsGroup())
    groups[groups.high]
  
  for i in 0..groups.high:
    let gr = groups[i]
    if gr.incl_hash == incl_hash and
      gr.excl_hash == excl_hash:
         group_next = gr; break

  if group_next.isNil:
    group_next = addGroup()
    group_next.id = id_next_group
    group_next.ents = newSeqOfCap[eid]((AMOUNT_ENTS/2).int)
    group_next.incl_hash = incl_hash
    group_next.excl_hash = excl_hash
    init_indices(group_next.indices)
    var storage_owner = newSeq[CompStorageMeta]()
    
    for id in incl_sig:
      group_next.incl_sig.add(id)
      metas_storage[id].groups.add(group_next)
      storage_owner.add(metas_storage[id])
    for id in excl_sig:
      group_next.excl_sig.add(id)
      metas_storage[id].groups.add(group_next)
   
    storage_owner.sort(sortStorages)
    tryinsert(group_next,storage_owner[0][].ents)

    id_next_group += 1
  
  incl_sig = {}
  excl_sig = {}
  group_next

proc updateGroups*(self: eid, cid: uint16) {.inline.} =
  let groups = metas_storage[cid].groups
  for group in groups:
    let grouped = self.partof(group)
    let matched = self.match(group)
    if grouped and not matched:
      group.remove(self)
    elif not grouped and matched:
      group.insert(self)

template group*(ecs: Ecs, t: varargs[untyped]): EcsGroup =
  var group_cached {.global.} : EcsGroup
  if group_cached.isNil:
    group_cached = init_group(t)
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
  ecs.dirty = false
  let meta = metas[self.id]
  for cid in meta.sig:
    let groups = metas_storage[cid].groups
    for group in groups:
      if not self.partof(group) and self.match(group):
          group.insert(self)
