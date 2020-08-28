import utils/actors_log
#import utils/actors_log_old
#i#mport utils/actors_profile

#log.trace "me"

log.add "app.log"

proc Tester() =
  log.trace "me"

Tester()
# log.trace "pony" 
# log.info "pon2y"
# log.info "pony master"
# log.info "pony master", "sequa", "alpaca" 
log.debug "pinya"
log.info "alpaca"
log.warn "OPA"
log.error "ERR"

#log.benchmark "DSFSD":

# for i in 0..100:
#   log.info "pon2y"