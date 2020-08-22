{.used.}
{.experimental: "dynamicBindSym".}

import strutils
import macros

import ecs_h
import ecs_debug
import ecs_group

var e1 {.global.} : ptr ent
var e2 {.global.} : ptr ent

# 0,0 1,2 
# 0,2 1,0 (swap age), inject ents[e2.id]
# 1,2,0,0 (swap id)

func incAge*(age: var int) =
  if age == high(int):
    age = 0
  else: age += 1

template entity*(ecs: Ecs, code: untyped) =
  e1 = ents[AMOUNT_ENTS-FREE_ENTS].addr
  e2 = ents[e1.id].addr 
  FREE_ENTS -= 1
  swap(e1,e2)
  block:
    let e {.inject,used.} : ent = (e1.id,e2.age) #(e1.id,e2.age)
    ecs.dirty = true
    code
    ecs.dirty = false
    ecs_group.bind(e.id.eid)

template entity*(ecs: Ecs, name: untyped, code: untyped): untyped =
  e1 = ents[AMOUNT_ENTS-FREE_ENTS].addr
  e2 = ents[e1.id].addr
  FREE_ENTS -= 1
  swap(e1,e2)
  let name {.inject,used.} : ent = (e1.id,e2.age) #ents[e2.id]
  block:
    ecs.dirty = true
    let e {.inject,used.} : ent = name
    code
    ecs.dirty = false
    ecs_group.bind(name.id.eid)

proc alive*(self:ent): bool =
  let cached = ents[self.id].addr
  cached.id == self.id and cached.age == self.age


proc empty*(meta: ptr EntMeta, self: eid) {.inline,used.} =

  for i in countdown(meta.sig_groups.high,0):
    groups[meta.sig_groups[i]].remove(self)
  
  for i in countdown(meta.sig.high,0):
    metas_storage[meta.sig[i].int].actions.remove(self)

  FREE_ENTS += 1
  ents[self.int].age.incAge()
  system.swap(ents[self.int],ents[AMOUNT_ENTS-FREE_ENTS])
  meta.sig.setLen(0) 
  meta.sig_groups.setLen(0)
  meta.parent = ent.nil.id.eid
  meta.childs.setLen(0)

proc release*(self: ent|eid) {.inline.} =
  # Release is called via kill, don't use manually
  let meta = metas[self.id].addr
  for i in countdown(meta.childs.high,0):
    release(meta.childs[i])
  empty(meta,self)

proc kill*(self: ent|eid) {.inline.} =
  check_error_release_empty(self)
  release(self)

proc kill*(ecs: Ecs) =
  template empty(meta: ptr EntMeta, id: int)=
      FREE_ENTS += 1
      ents[id].age.incAge()
      system.swap(ents[id],ents[AMOUNT_ENTS-FREE_ENTS])
      meta.sig.setLen(0)
      meta.sig_groups.setLen(0)
      meta.parent = ent.nil.eid
      meta.childs.setLen(0)
 #clean groups
  for g in groups:
    g.ents.setLen(0)
 #find all entities on the layer and release them
  for i in 0..metas.high:
    let meta = metas[i].addr
    empty(meta,i)
 #clean storages
  for st in metas_storage:
    st.actions.cleanup()

proc parent*(self: ent): ent =
  self.meta.parent

proc `parent=`*(self: ent ,other: ent) =
  let meta = self.meta
  if other == ent.nil or meta.parent.int != eid.nil.int:
    var parent_meta = meta.parent.meta
    let index = parent_meta.childs.find(self)
    parent_meta.childs.del(index)
  
  meta.parent = other
 
  if meta.parent.int != eid.nil.int:
    var parent_meta = other.meta
    parent_meta.childs.add(self)


template has*(self:ent|eid, T: typedesc): bool =
  T.has(self)
template has*(self:ent|eid, T: typedesc): bool =
  T.has(self)
template has*(self:ent|eid, T,Y: typedesc): bool =
  T.has(self) and 
  Y.has(self)
template has*(self:ent|eid, T,Y,U: typedesc): bool =
  T.has(self) and
  Y.has(self) and
  U.has(self)
template has*(self:ent|eid, T,Y,U,I: typedesc): bool =
  T.has(self) and
  Y.has(self) and
  U.has(self) and
  I.has(self)
template has*(self:ent|eid, T,Y,U,I,O: typedesc): bool =
  T.has(self) and
  Y.has(self) and
  U.has(self) and
  I.has(self) and
  O.has(self)
template has*(self:ent|eid, T,Y,U,I,O,P: typedesc): bool =
  T.has(self) and
  Y.has(self) and
  U.has(self) and
  I.has(self) and
  O.has(self) and
  P.has(self)

macro tryget*(this: ent, args: varargs[untyped]): untyped =
  var command = nnkCommand.newTree(
                  nnkDotExpr.newTree(
                      ident($this),
                      ident("has")))
  var code = args[args.len-1]
  for i in 0..args.len-2:
    var elem = args[i]
    command.add(ident($elem))
    var elem_name = $elem
    formatComponentAlias(elem_name) 
    var elem_var = toLowerAscii(elem_name[0]) & substr(elem_name, 1)
    formatComponent(elem_var)
    var n = nnkLetSection.newTree(
        nnkIdentDefs.newTree(
            newIdentNode(elem_var),
            newEmptyNode(),
            nnkDotExpr.newTree(
                newIdentNode($this),
                newIdentNode(elem_var)
            ),
        )
    )
    code.insert(0,n)
  
  var node_head = nnkStmtList.newTree(
      nnkIfStmt.newTree(
          nnkElifBranch.newTree(
              command,
               nnkStmtList.newTree(
                   code
               )
          )
      )
  )
  result = node_head