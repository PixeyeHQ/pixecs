import ecs_h
import strformat

##========================================
##@debugger
##========================================

when defined(debug):
  type
    EcsError* = object of ValueError

template px_ecs_debug_remove*(self: ent|eid, st_indices: ptr seq[int],st_ents: ptr seq[eid], t: typedesc): untyped {.used.}=
  when defined(debug):
    block:
      let arg1 {.inject.} = $t
      let arg2 {.inject.} = self.id
      if st_indices[][self.id] < st_ents[].len:
        raise newException(EcsError,&"\n\nYou are trying to remove a {arg1} that is not attached to entity with id {arg2}\n")

template px_ecs_debug_release*(self: ent|eid): untyped {.used.} =
  when defined(debug):
    block:
      let arg1 {.inject.} = self.id
      let arg2 {.inject.} = &"\n\nYou are trying to release an empty entity with id {arg1}. Entities without any components are released automatically.\n"
      if px_ecs_meta[self.id].sig.len == 0:
        raise newException(EcsError,arg2)