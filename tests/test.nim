import utils/actors_log
import utils/actors_profile
#import utils/actors_log_old

#log.trace "me"

logAdd "app.log"
import random
proc Tester() =
  logError "Invalid alpaca id"

proc GetDamage =
  logTrace "Get Damage"

proc AlpacaHit =
  GetDamage()


log_info "Game started!"
log_warn "Something is wrong"
log "Alpaca is created"
log "Alpaca is moving"

profileStart "Bench mk1":
  AlpacaHit()
  Tester()

profileLog()
#log.benchmark "DSFSD":

# for i in 0..100:
#   log.info "pon2y"