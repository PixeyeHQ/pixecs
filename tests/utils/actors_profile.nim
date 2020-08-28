## Created by Pixeye | dev@pixeye.com   
##
## This module is used for measuring performance.
##
## * ``profileStart "name": code`
## * ``profileLog``
## * ``profileClear``


{.used.}
import times
import std/monotimes
import strformat
import tables
import strutils

import actors_log

type ProfileElement = object
  name: string
  t0, t1: MonoTime
  total_calls: int
  total_time: int64
  cache: seq[Duration]

var pairs = initTable[string,ProfileElement]()

proc profile_start(arg: string): ptr ProfileElement {.inline.} =
  if not pairs.hasKey(arg):
   var el: ProfileElement   
   pairs.add(arg,el)
  let el = addr pairs[arg]
  el.t0 = getMonoTime()
  el.name = arg
  el

proc profile_end(el: ptr ProfileElement) {.inline.} =
  el.t1 = getMonoTime()
  var v = el.t1-el.t0
  el.total_time += v.inNanoseconds
  el.total_calls+=1
  el.cache.add(v)

proc profileLog*()= 
  var benches = ""
  for pe in pairs.mvalues:
      let elapsed_raw = pe.total_time.float64/1000000000.float64
      let total =  pe.total_calls
      if pe.total_calls>1:
          let elapsed     = formatFloat(elapsed_raw,format = ffDecimal,precision = 4)
          let elapsed_avr = formatFloat(elapsed_raw / total.float64,format = ffDecimal,precision = 9)
          let elapsed_min = formatFloat(pe.cache.min.inNanoseconds.float64/1000000000.float64,format = ffDecimal,precision = 9)
          let elapsed_max = formatFloat(pe.cache.max.inNanoseconds.float64/1000000000.float64,format = ffDecimal,precision = 9)
          benches.add(&"⯈ {pe.name}: {elapsed}s -> {total} iterations, avg: {elapsed_avr}s min: {elapsed_min}s max: {elapsed_max}s\n")
      else:
          let elapsed     = formatFloat(elapsed_raw,format = ffDecimal,precision = 9)
          benches.add(&"⯈ {pe.name}: {elapsed}s\n")
  log.benchmark benches 

template profileStart*(benchmarkName: string, code: untyped): untyped  =
  block:
    let el = profile_start(benchmarkName)
    code
    profile_end(el) 

proc profileClear*()=
  pairs = initTable[string,ProfileElement]()

