import utils/actors_profile
import utils/actors_log
import pixecs

type CompA* = object
  arg*  : float
  arg2* : float
type CompB* = object
  arg*:int
type CompC* = object
  arg*:int
type TagHit* = distinct int

# Initialize ecs and define amount of entities. 
# The size of entities doesn't change so allocate as much as you need.
# Also keep in mind that in this ecs there is no 'WORLD' concept. You have only one registry.
# This is may change in future but I don't see the point for multiword stuff right now.  
logAdd stdout

ecsInit(1_000_000) 
logInfo "Initialize ecs fo 1 000 000 entities"
# Register components

ecsAdd CompA
ecsAdd CompB
ecsAdd CompC


proc entity_create_one_comp() =
  profile "Entity Create  [1comp]":
    for x in 0..<AMOUNT_ENTS:
      ecsEntity:
        let ca = e.get CompA
        ca.arg = 10

proc entity_create_two_comp() =
  profile "Create Entity + two comp + group":
    for x in 0..<AMOUNT_ENTS:
      ecsEntity:
        let ca = e.get CompA
        let cb = e.get CompB
        ca.arg = 10
        cb.arg = 10

proc entity_kill_one_comp() =
  profile "Entity Release [1comp]":
    for e in ecsAll():
      e.release

proc iterate_group() =
  profile "iterate group":
    # you can iterate through cached group or get one dynamically. it's the same.
    for e in ecsGroup(CompA):
      let ca = e.compA
      ca.arg+=1

proc iterate_query() =
  profile "iterate query":
    for ca in ecsQuery(CompA):
        ca.arg += 1

proc iterate_query_with_ent() =
  profile "iterate query with ent":
    for e, ca in ecsQuery(Ent,CompA):
      ca.arg += 1

# create group of entities that have CompA and don't have CompB
var players {.used.} = ecsGroup(CompA,!CompB)
var everyone {.used.} = ecsGroup(CompA)


for x in 0..<1:
  entity_create_one_comp()
  entity_kill_one_comp()

proc test2() = logTrace "This is a TEST"

proc test() = test2()

test()

  # entity_create_two_comp()
  # iterate_group()
  # iterate_query()
  # iterate_query_with_ent()
  # ecsRelease()


profileLog()

