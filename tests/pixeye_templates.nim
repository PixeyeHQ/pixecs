import utils/actors_profile
import utils/actors_log
import pixecs

ecs.init(1_000_000)

type CompA = object
  arg: int
type CompB = object
  arg: int

ecs.add CompA

buildComp(CompA,1_000_000)
buildComp(CompB,1_000_000)


#var v = storageCompA
iterator queryy*(ecs:Ecs, _: type[CompA]): ptr CompA =
  for i in countdown(storageCompA.high,0):
    yield storageCompA[i].addr

for x in 0..<1_000_000:
  ecs.entity:
    let ca = e.get CompA

for x in 0..<120:
  profile.start "template":
    for ca in ecs.query(CompA):
      ca.arg+=1
profile.log
profile.clear
for x in 0..<120:
  profile.start "macro":
    for ca in ecs.queryy(CompA):
      ca.arg+=1

profile.log

# for ca in ecs.query(CompA):
#   ca.arg+=1

# echo getCompA(0).arg
# storageCompA = newSeq[CompA](10)
# echo getCompA()
#formatStore(CompB)


#echo storageCompA.len
# impl_store2(CompA)
# impl_store2(CompB)


# var s = CompA.getTheStorage()
# echo s[].len

#impl_store2(CompB)
