{.used.}

import times
import strformat
import tables
import strutils

import actors_log


type ProfileElement = tuple
  name: string
  t0, t1: float
  total_calls: int
  total_time: float
type Profile = object


var profile* : Profile
var  index   : int
var  pairs   = initTable[string,ProfileElement]()


template profileStart(arg: string) =
    if not pairs.hasKey(arg):
     var el: ProfileElement   
     pairs.add(arg,el)
     index+=1
    pairs[arg].name = arg
    pairs[arg].t0 = cpuTime()

template profileEnd(name:string) =
    var el = addr pairs[name]
    el.t1 = cpuTime()
    el.total_time+=el.t1-el.t0
    el.total_calls+=1

template log*(this: Profile): untyped= 
    var benches : string
    block:
        var i: int
        for pe in pairs.values:
            let arg1 {.inject.} = pe.name
            let arg2 {.inject.} = pe.total_time
            let arg3 {.inject.} =  pe.total_calls
            if pe.total_calls>1:
                let elapsedStr{.inject.} = formatFloat(arg2 / arg3.float,format = ffDecimal,precision = 9)
                let elapsedStr0{.inject.} = formatFloat(arg2,format = ffDecimal,precision = 9)
                if i==index:
                    benches.add(&"Time elapsed for {arg1}: {elapsedStr0} seconds over {arg3} iterations, averaging: {elapsedStr} seconds\n")
                else: benches.add(&"Time elapsed for {arg1}: {elapsedStr0} seconds over {arg3} iterations, averaging: {elapsedStr} seconds\n") 
            else:
                let elapsedStr{.inject.} = formatFloat(arg2,format = ffDecimal,precision = 9)
                if i==index:
                    benches.add(&"Time elapsed for {arg1}: {elapsedStr} seconds\n")
                else: benches.add(&"Time elapsed for {arg1}: {elapsedStr} seconds\n")    

            i+=1
        log benchmark, benches 
        index = 0

template start*(this: Profile,benchmarkName: string, code: untyped): untyped  =
  block:
    profileStart(benchmarkName)
    code
    profileEnd(benchmarkName) 

proc clear*(this: Profile)=
    pairs = initTable[string,ProfileElement]()

