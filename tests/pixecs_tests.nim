{.used.}

import unittest
import pixecs
import utils/actors_log

type CompA = object
  arg: int
type CompB = object
  arg: int
type TagB = distinct int

ecsInit(100)

ecsAdd CompA
ecsAdd CompB
ecsAdd TagB, AsTag

var groupA  {.used.} = ecsGroup(CompA)
var groupB  {.used.} = ecsGroup(CompB)
var groupAB {.used.} = ecsGroup(CompA,CompB)
suite "Pixeye Ecs":
  setup:
    if FREE_ENTS != AMOUNT_ENTS:
      ecsRelease()
  test "Entity default don't exist":
    var entity = ent.default
    check(entity.exist==false)
  test "Entity create [ecsCreate]":
    var entity = ecsCreate()
    entity.bind()
    check(entity.exist)
  test "Entity create [ecsEntity]":
    var entity: ent
    ecsEntity:
      entity = e
    check(entity.exist)
  test "Entity create [ecsEntity named]":
    ecsEntity entity:
      discard
    check(entity.exist)
  test "Entity default don't have components":
    var entity = ent.default
    check(entity.has(CompA)==false)
  test "Entity add component [CompA]":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
    check(entity.has CompA)
  test "Entity try get component [CompA]":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
    var valid = false
    entity.tryGet(CompA):
      ca.arg-=1
      valid = true
    check(valid == true)
  test "Entity release":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
    entity.release()
    check(entity.exist==false)
  test "Entity released don't have components":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
    entity.release()
    check(entity.has(CompA)==false)
  test "Entity get released when last component is removed":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
    entity.remove CompA
    check(entity.exist==false)
  test "Entity age changes":
    var temp_e = ecsCreate()
    temp_e.release()
    var temp_e2 = ecsCreate()
    check(temp_e.id==temp_e2.id)
    check(temp_e.age!=temp_e2.age)
  test "Entity is added to a group [GroupA]":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
    check(groupA.len==1)
    check(groupA[0]==entity)
    check(groupB.len==0)
  test "Entity released is removed from all accompanying groups [GroupA,GroupB,GroupAB]":
    ecsEntity entity:
      var ca {.used.} = e.get CompA
      var cb {.used.} = e.get CompB
    check(groupA.len==1 and groupB.len==1 and groupAB.len==1)
    check(groupA[0]==entity and groupB[0]==entity and groupAB[0]==entity)
    entity.release()
    check(groupA.len==0 and groupB.len==0 and groupAB.len==0)
  test "Entity add tag 5 times [TagB]":
    ecsEntity entity:
      e.inc TagB, 5
    check(entity.has TagB)
    check(entity.tagB==5)
  test "Entity removes tag if tag size is zero [TagB]":
    ecsEntity entity:
      e.inc TagB, 5
    check(entity.has TagB)
    check(entity.tagB==5)
    entity.dec TagB, 5
    check(entity.has(TagB)==false)
    check(entity.exist==false)
  test "Group Iteration, increment value in a component [CompA,10]":
    ecsEntity entity:
      let ca {.used.} = e.get CompA
    while entity.ca.arg < 10:
      for e in groupA:
        let ca = e.compa
        ca.arg+=1
    check(entity.ca.arg==10)
  test "Group Iteration, release entity while iterating":
    ecsEntity entity:
      let ca {.used.} = e.get CompA
    ecsEntity entity2:
      let ca {.used.} = e.get CompA
    while entity2.ca.arg < 10:
      for e in groupA:
        let ca = e.compa
        ca.arg+=1
        if ca.arg==1 and e == entity:
          e.release()
    check(entity2.compa.arg==10)
    check(entity.exist==false)
    check(groupB.len==0)