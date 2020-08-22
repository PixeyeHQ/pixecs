{.used.}

import unittest
import pixecs
import utils/actors_log

type CompA = object
  arg: int
type TagB = distinct int


ecs.init(1_00)

ecs.add CompA  
ecs.add TagB, AsTag

var group = ecs.group(CompA)

suite "Pixeye Ecs":
  test "Create 100 entities":
    for x in 0..<AMOUNT_ENTS:
      ecs.entity:
        let ca {.used.} = e.get CompA
        e.inc TagB
    check(FREE_ENTS==0)
  test "No Group Duplicates":
    check(group==ecs.group(CompA))
  test "Kill all entities":
    for e in ecs.all:
      e.kill
    check(FREE_ENTS==AMOUNT_ENTS)
  test "Groups are cleaned":
    check(group.ents.len==0)
  test "Entity ver changed":
    var temp_e :ent = (0,0)
    ecs.entity:
      temp_e = e
      let ca {.used.} = e.get CompA
    temp_e.kill
    ecs.entity another:
      let ca {.used.} = e.get CompA
    check(another.age!=temp_e.age)
    another.kill
  test "Entity killed without components":
    ecs.entity another:
      let ca {.used.} = e.get CompA
    another.remove CompA
    check(another.alive==false)
  test "Increment tag by 10":
    ecs.entity another:
      another.inc TagB, 10
    check(another.tagB == 10)
    another.kill
  test "Remove tag when it's value = 0":
    ecs.entity another:
      another.inc TagB, 10
    another.dec TagB, 10
    check(another.has(TagB)==false)
    