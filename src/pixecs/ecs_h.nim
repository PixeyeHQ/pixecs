import strutils

var AMOUNT_ENTS*  = 0
var FREE_ENTS*    = 0

type #@atomic 
  
  ent* = tuple[id: int, age: int]
  eid* = distinct int
  cid* = uint16
  Ent* = ent

type #@ecs

  CompType* = enum
    AsComp,
    AsTag

  EntMeta* = object
    childs*    : seq[eid]
    sig*       : seq[cid]
    sig_groups*: seq[cid]
    parent*    : eid

  Ecs*     = ref object
    dirty* : bool
 
  EcsGroup* = ref object
    id*        : cid
    indices*   : seq[int]
    ents*      : seq[eid]
    incl_hash* : int      # include 
    incl_sig*  : seq[cid]
    excl_hash* : int      # exclude
    excl_sig*  : seq[cid]
  
  CompStorageMeta* = ref object
    indices*: ptr seq[int]
    ents*   : ptr seq[eid]
    groups* : seq[EcsGroup]
    actions*: IStorage
  
  IStorage* = object
    remove* : proc (self: eid)
    cleanup*: proc ()

var  #@variables
  metas*         : seq[EntMeta]
  ents*          : seq[ent]
  ecs*           : Ecs
  groups*        : seq[EcsGroup]
  metas_storage* : seq[CompStorageMeta]

#@utils
template `nil`*(T: typedesc[ent]): ent =
  (int.high, 0)
template `nil`*(T: typedesc[eid]): eid =
  int.high.eid
converter toEnt*(x: eid): ent =
  (x.int,ents[x.int].age)
converter toEid*(x: ent): eid =
  x.id.eid
template id*(self: eid): int =
  self.int



proc meta*(self: ent): ptr EntMeta {.inline.} =
  metas[self.id].addr

proc meta*(self: eid): ptr EntMeta {.inline.} =
  metas[self.int].addr

proc init_indices*(self: var seq[int]) {.used.} =
  self = newSeq[int](AMOUNT_ENTS)
  for i in 0..self.high:
    self[i] = ent.nil.id

proc formatComponentAlias*(s: var string) {.used.}=
  var indexes : array[8,int]
  var i = 0
  var index = 0
  while i<s.len:
     if s[i] in 'A'..'Z': 
       indexes[index] = i
       index += 1
       assert index < 7, "too long name"

     i+=1
  if index>=2:
    delete(s,1,indexes[1]-1)
  s = toUpperAscii(s[0]) & substr(s, 1)
proc formatComponent*(s: var string) {.used.}=
  var indexes : array[8,int]
  var i = 0
  var index = 0
  while i<s.len:
     if s[i] in 'A'..'Z': 
       indexes[index] = i
       index += 1
       assert index < 7, "too long name"

     i+=1
  if index>=2:
    delete(s,1,indexes[1]-1)
  s = toLowerAscii(s[0]) & substr(s, 1)
proc formatComponentLong*(s: var string) {.used.}=
  var indexes : array[8,int]
  var i = 0
  var index = 0
  while i<s.len:
     if s[i] in 'A'..'Z': 
       indexes[index] = i
       index += 1
       assert index < 7, "too long name"

     i+=1
  if index>=2:
    delete(s,1,indexes[1]-1)
  s = toUpperAscii(s[0]) & substr(s, 1)



