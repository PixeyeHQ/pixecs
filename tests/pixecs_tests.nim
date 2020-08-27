{.used.}

import unittest
import pixecs
import utils/actors_log

type CompA = object
  arg: int
type TagB = distinct int


ecsInit(1_00)
ecsAdd CompA  
ecsAdd TagB, AsTag



var group = ecsGroup(CompA)

suite "Pixeye Ecs":
  test "Create 100 entities":
    for x in 0..<AMOUNT_ENTS:
      ecs_entity:
        let ca {.used.} = e.get CA
        e.inc TagB
    check(FREE_ENTS==0)
  test "No Group Duplicates":
    check(group==ecsGroup(CompA))
  test "Kill all entities":
    for e in ecsAll():
      e.release
    check(FREE_ENTS==AMOUNT_ENTS)
  test "Groups are cleaned":
    check(group.ents.len==0)
  test "Entity ver changed":
    var temp_e :ent = (0,0)
    ecs_entity:
      temp_e = e
      let ca {.used.} = e.get CompA
    temp_e.release
    ecs_entity another:
      let ca {.used.} = e.get CompA
    check(another.age!=temp_e.age)
    another.release
  test "Entity killed without components":
    ecs_entity another:
      let ca {.used.} = e.get CompA
    another.remove CompA
    check(another.exist==false)
  test "Increment tag by 10":
    ecs_entity another:
      another.inc TagB, 10
    check(another.tagB == 10)
    another.release
  test "Remove tag when it's value = 0":
    ecsEntity another:
      another.inc TagB, 10
    another.dec TagB, 10
    check(another.has(TagB)==false)
    