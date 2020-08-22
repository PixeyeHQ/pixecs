import ecs_h
import strformat

when defined(debug):
  type
    EcsError* = object of ValueError

template check_error_remove_component*(this: ent|eid, t: typedesc): untyped {.used.}=
  when defined(debug):
    block:
      let arg1 {.inject.} = $t
      let arg2 {.inject.} = this.id
      let id = t.id.int
      var valid = true
      if not id in metas[this.id].sig:
        valid = false
      if not valid:
        raise newException(EcsError,&"\n\nYou are trying to remove a {arg1} that is not attached to entity with id {arg2}\n")

template check_error_release_empty*(this: ent|eid): untyped {.used.} =
  when defined(debug):
    block:
      let arg1 {.inject.} = this.id
      let arg2 {.inject.} = &"\n\nYou are trying to release an empty entity with id {arg1}. Entities without any components are released automatically.\n"
      if metas[this.id].sig.len == 0:
        raise newException(EcsError,arg2)
