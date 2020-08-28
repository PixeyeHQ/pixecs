{.used.}
{.experimental: "dynamicBindSym".}

import macros
import strutils

import ecs_h
import ecs_group

var e1 {.global.} : ptr ent
var e2 {.global.} : ptr ent

func px_ecs_incAge*(age: var int) =
  if age == high(int):
    age = 0
  else: age += 1


template px_ecs_ent(): untyped =
  # 0,0 1,2 
  # 0,2 1,0 (swap age), inject ents[e2.id]
  # 1,2,0,0 (swap id)
  e1 = px_ecs_ents[AMOUNT_ENTS-FREE_ENTS].addr
  e2 = px_ecs_ents[e1.id].addr 
  FREE_ENTS -= 1
  swap(e1,e2)
  

template ecsEntity*(code: untyped) =
  px_ecs_ent()
  block:
    let e {.inject,used.} : ent = (e1.id,e2.age) #(e1.id,e2.age)
    px_ecs_dirty = true
    code
    ecs_group.bind(e.id.eid)

template ecsEntity*(name: untyped, code: untyped): untyped =
  px_ecs_ent()
  let name {.inject,used.} : ent = (e1.id,e2.age) #ents[e2.id]
  block:
    px_ecs_dirty = true
    let e {.inject,used.} : ent = name
    code
    ecs_group.bind(name.id.eid)

proc ecsCreate*(): ent =
  ##Create an enity. Call ecs.bind afrter creating and setting up components.
  ##Alternative: use entity template to create an entity.
  px_ecs_ent()
  px_ecs_dirty = true
  (e1.id,e2.age)

proc exist*(self:ent): bool =
  let cached = px_ecs_ents[self.id].addr
  cached.id == self.id and cached.age == self.age

proc px_ecs_empty*(meta: ptr EntMeta, self: eid) {.inline,used.} =
  for i in countdown(meta.sig_groups.high,0):
    px_ecs_remove(px_ecs_groups[meta.sig_groups[i]],self)
    
  for i in countdown(meta.sig.high,0):
    px_ecs_meta_comp[meta.sig[i].int].actions.remove(self)

  FREE_ENTS += 1
  px_ecs_incAge(px_ecs_ents[self.int].age)
  system.swap(px_ecs_ents[self.int],px_ecs_ents[AMOUNT_ENTS-FREE_ENTS])
  meta.sig.setLen(0) 
  meta.sig_groups.setLen(0)
  meta.parent = ent.nil.id.eid
  meta.childs.setLen(0)

proc px_ecs_release*(self: ent|eid) {.inline.} =
  # Release is called via release, don't use this
  let meta = px_ecs_meta[self.id].addr
  for i in countdown(meta.childs.high,0):
    px_ecs_release(meta.childs[i])
  px_ecs_empty(meta,self)

proc release*(self: ent|eid) {.inline.} =
  px_ecs_debug_release(self)
  px_ecs_release(self)

proc ecsRelease*() =
  template empty(meta: ptr EntMeta, id: int)=
      FREE_ENTS += 1
      px_ecs_incAge(px_ecs_ents[id].age)
      system.swap(px_ecs_ents[id],px_ecs_ents[AMOUNT_ENTS-FREE_ENTS])
      meta.sig.setLen(0)
      meta.sig_groups.setLen(0)
      meta.parent = ent.nil.eid
      meta.childs.setLen(0)
 #clean groups
  for g in px_ecs_groups:
    g.ents.setLen(0)
 #find all entities on the layer and release them
  for i in 0..px_ecs_meta.high:
    let meta = px_ecs_meta[i].addr
    empty(meta,i)
 #clean storages
  for st in px_ecs_meta_comp:
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

macro tryGet*(this: ent, args: varargs[untyped]): untyped =
  var command = nnkCommand.newTree(
                  nnkDotExpr.newTree(
                      ident($this),
                      ident("has")))
  var code = args[args.len-1]
  for i in 0..args.len-2:
    var elem = args[i]
    command.add(ident($elem))
    var elem_name = $elem
    px_ecs_format_comp_alias(elem_name) 
    var elem_var = toLowerAscii(elem_name[0]) & substr(elem_name, 1)
    px_ecs_formatComp(elem_var)
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