#[
  Created by Mitrofanov Dmitry "Pixeye" on 20/08/2020 
  Email: dev@pixeye.com
]#

import pixecs/ecs_h
import pixecs/ecs_ent
import pixecs/ecs_comp
import pixecs/ecs_group

# Importing/Exporting is something I don't get in Nim. The routine below must be refactoredm
# but I don't know how yet. Excepting 2/3 of elements is insane. 
export
  ecs_comp,
  ecs_group,
  ecs_ent

export ecs_group except
  updateGroups,
  binarysearch,
  init_group,
  partof,
  match,
  insert,
  remove,
  `bind`
export ecs_h except
  init_indices,
  formatComponentAlias,
  formatComponent,
  formatComponentLong,
  formatComponentPrettyAndLong,
  formatComponentPretty,
  meta,
  metas,
  ents


proc init*(ecs: var Ecs, ent_amount: int)  =
  ecs = Ecs()
  AMOUNT_ENTS   = ent_amount
  FREE_ENTS     = ent_amount
  groups        = newSeq[EcsGroup]()
  metas         = newSeq[EntMeta](AMOUNT_ENTS)
  metas_storage = newSeq[CompStorageMeta](0)
  ents          = newSeq[ent](AMOUNT_ENTS)
  for i in 0..<AMOUNT_ENTS:
    ents[i] = (i,1)
    metas[i].sig        = newSeqOfCap[cid](3)
    metas[i].sig_groups = newSeqOfCap[cid](1)
    metas[i].childs = newSeqOfCap[eid](0)
    metas[i].parent = ent.nil


iterator all*(self:Ecs): eid =
  for i in countdown(ents.high,0):
    yield ents[i].id.eid