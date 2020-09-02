import macros
import strutils
import strformat

const ENTITY_BATCH* {.intdefine.}: int = 0

var PX_ECS_DEFAULT_GROUP_SIZE*  = 0
var ENTITY_FREE*                  = 0

#----------------------------------------
#@types
#----------------------------------------

type
  ent* = tuple[id: int, age: int]

  eid* = distinct int

  cid* = uint16

  Ent* = ent

  CompType* = enum
    AsComp,
    AsTag

  EntMeta* = object
    childs*    : seq[eid]
    sig*       : seq[cid]
    sig_groups*: seq[cid]
    parent*    : eid

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

#----------------------------------------
#@variables
#----------------------------------------

var
  px_ecs_dirty*         : bool
  px_ecs_meta*          : seq[EntMeta]
  px_ecs_ents*          : seq[ent]
  px_ecs_groups*        : seq[EcsGroup]
  px_ecs_meta_comp*     : seq[CompStorageMeta]

#----------------------------------------
#@utils
#----------------------------------------

template `nil`*(T: typedesc[ent]): ent =
  (int.high, 0)
template `nil`*(T: typedesc[eid]): eid =
  int.high.eid
converter toEnt*(x: eid): ent =
  (x.int,px_ecs_ents[x.int].age)
converter toEid*(x: ent): eid =
  x.id.eid
template id*(self: eid): int =
  self.int


proc meta*(self: ent): ptr EntMeta {.inline.} =
  px_ecs_meta[self.id].addr

proc meta*(self: eid): ptr EntMeta {.inline.} =
  px_ecs_meta[self.int].addr

proc px_ecs_genIndices*(self: var seq[int]) {.used.} =
  self = newSeq[int](ENTITY_BATCH)
  for i in 0..self.high:
    self[i] = ent.nil.id

#----------------------------------------
#@formatters
#----------------------------------------

proc px_ecs_format_compalias*(s: var string) {.used.}=
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

proc px_ecs_format_comp*(s: var string) {.used.}=
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

macro px_ecs_format_tags*(T: typedesc): untyped {.used.}=
  let tName = strVal(T)
  var proc_name = tName  
  proc_name  = toLowerAscii(proc_name[0]) & substr(proc_name, 1)
  px_ecs_formatComp(proc_name)
  var source = &("""
  template `{proc_name}`*(self: ent|eid): int =
      px_ecs_get(self,{tName})
      """)
  result = parseStmt(source)

macro px_ecs_format_getCompAliasLong *(T: typedesc): untyped {.used.}=
  let tName = strVal(T)
  var proc_name = tName  
  proc_name  = toLowerAscii(proc_name[0]) & substr(proc_name, 1)
  px_ecs_formatComp(proc_name)
  var source = &("""
  template `{proc_name}`*(self: ent|eid): ptr {tName} =
      px_ecs_get(self,{tName})
      """)
  result = parseStmt(source)

macro px_ecs_format_getCompAlias*(t: typedesc): untyped {.used.}=
  let tName = strVal(t)
  var proc_name = tName  
  px_ecs_formatComp(proc_name)
  var source = ""
  source = &("""
    template `{proc_name}`*(self: ent|eid): ptr {tName} =
        px_ecs_get(self,{tName})
        """)

  result = parseStmt(source)
