## Created by Pixeye | dev@pixeye.com
##
## Entity-Component-System (ECS) module.

{.used.}

import pixecs/ecs_h
import pixecs/ecs_ent
import pixecs/ecs_comp
import pixecs/ecs_group

export ecs_comp
export ecs_group
export ecs_ent
export ecs_h except
  EcsGroup,
  CompStorageMeta,
  IStorage,
  EntMeta,
  meta

proc ecsInit*()  =
  ENTITY_FREE     = ENTITY_BATCH
  PX_ECS_DEFAULT_GROUP_SIZE = (ENTITY_BATCH/2).int
  px_ecs_groups        = newSeq[EcsGroup]()
  px_ecs_meta          = newSeq[EntMeta](ENTITY_BATCH)
  px_ecs_meta_comp     = newSeq[CompStorageMeta](0)
  px_ecs_ents          = newSeq[ent](ENTITY_BATCH)
  for i in 0..<ENTITY_BATCH:
    px_ecs_ents[i] = (i,1)
    px_ecs_meta[i].sig        = newSeqOfCap[cid](3)
    px_ecs_meta[i].sig_groups = newSeqOfCap[cid](1)
    px_ecs_meta[i].childs = newSeqOfCap[eid](0)
    px_ecs_meta[i].parent = ent.nil


iterator ecsAll*: eid =
  for i in countdown(px_ecs_ents.high,0):
    yield px_ecs_ents[i].id.eid
