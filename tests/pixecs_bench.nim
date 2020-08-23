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
ecs.init(1_000_000) 
log "Initialize ecs fo 1 000 000 entities"
# Register components
ecs.add CompA
ecs.add CompB
ecs.add CompC

# All benches are located in the procs.
# Build setup: nim c --d:danger  --gc:boehm  --out:"bin\pixeye_ecs_bench"

proc entity_create_one_comp() =
  profile.start "Create Entity + one comp":
    for x in 0..<AMOUNT_ENTS:
      ecs.entity:
        let ca = e.get CompA
        ca.arg = 10

proc entity_create_two_comp() =
  profile.start "Create Entity + two comp + group":
    for x in 0..<AMOUNT_ENTS:
      ecs.entity:
        let ca = e.get CompA
        let cb = e.get CompB
        ca.arg = 10
        cb.arg = 10

proc entity_kill_one_comp() =
  profile.start "Kill Entity with one comp":
    for e in ecs.all:
      e.kill

proc iterate_group() =
  profile.start "iterate group":
    # you can iterate through cached group or get one dynamically. it's the same.
    for e in ecs.group(CompA):
      let ca = e.compA
      ca.arg+=1

proc iterate_query() =
  profile.start "iterate query":
    for ca in ecs.query(CompA):
        ca.arg += 1

proc iterate_query_with_ent() =
  profile.start "iterate query with ent":
    for e, ca in ecs.query(Ent,CompA):
      ca.arg += 1

# create group of entities that have CompA and don't have CompB
var players {.used.} = ecs.group(CompA,!CompB)
var everyone {.used.} = ecs.group(CompA)

for x in 0..<25:
  entity_create_one_comp()
  entity_kill_one_comp()

  entity_create_two_comp()
  iterate_group()
  iterate_query()
  iterate_query_with_ent()
  ecs.kill

profile.log


