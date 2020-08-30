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

var group {.used.} = ecsGroup(CompA)

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
    
    # var entity: ent
    # ecsEntity:
    #   entity = e
    # check(entity.exist)
    # for x in 0..<AMOUNT_ENTS:
    #   ecs_entity:
    #     let ca {.used.} = e.get CA
    #     e.inc TagB
    # check(FREE_ENTS==0)
  # test "No Group Duplicates":
  #   check(group==ecsGroup(CompA))
  # test "Kill all entities":
  #   for e in ecsAll():
  #     e.release
  #   check(FREE_ENTS==AMOUNT_ENTS)
  # test "Groups are cleaned":
  #   check(group.ents.len==0)
  # test "Entity ver changed":
  #   var temp_e :ent = (0,0)
  #   ecs_entity:
  #     temp_e = e
  #     let ca {.used.} = e.get CompA
  #   temp_e.release
  #   ecs_entity another:
  #     let ca {.used.} = e.get CompA
  #   check(another.age!=temp_e.age)
  #   another.release
  # test "Entity killed without components":
  #   ecs_entity another:
  #     let ca {.used.} = e.get CompA
  #   another.remove CompA
  #   check(another.exist==false)
  # test "Increment tag by 10":
  #   ecs_entity another:
  #     another.inc TagB, 10
  #   check(another.tagB == 10)
  #   another.release
  # test "Remove tag when it's value = 0":
  #   ecsEntity another:
  #     another.inc TagB, 10
  #   another.dec TagB, 10
  #   check(another.has(TagB)==false)
    