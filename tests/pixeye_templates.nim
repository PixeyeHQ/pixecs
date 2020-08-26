import utils/actors_profile
import utils/actors_log
import pixecs

ecs.init(1_000_000)

type CompA = object
  arg: int
type CompB = object
  arg: int

ecs.add(CompA)
ecs.add(CompB)


# buildComp(CompA,1_000_000)
# buildComp(CompB,1_000_000)


# var a = 0
# for x in 0..10000:
#   a += 1

# var b = a
#echo st_compa_id
#echo st_compb_id