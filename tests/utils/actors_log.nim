## Created by Pixeye | dev@pixeye.com   
##
## This module is used for async logging.
{.used.}

import times
import strutils
import strformat
import typeinfo
import system

type Log* = object

type Logger* = object
  file: File

type MsgKind = enum
  Write,Trace,Update,Stop

type Msg = object
  case kind: MsgKind
  of Write:
    w_code : string
    w_txt  : string
    w_line : int
    w_lvl  : uint8
  of Trace:
    t_txt  : string
    t_stack: seq[StackTraceEntry]
    t_lvl  : uint8
  of Update:
    u_logs: seq[Logger]
  of Stop:
    nil

const log* = Log()

const lv_trace = 0'u8
const lv_debug = 1'u8
const lv_info  = 2'u8
const lv_warn  = 3'u8
const lv_error = 4'u8
const lv_bench = 5'u8

const names_std: array[6, string] = ["\e[0;32mTrace:\e[39m","\e[0;32mDebug:\e[39m","\e[0;36mInfo: \e[39m","\e[0;33mWarn: \e[39m","\e[0;31mError:\e[39m", "\e[0;36mBenchmark:\e[39m"]
const names    : array[6, string] = ["Trace:", "Debug:","Info: ","Warn: ","Error:", "Benchmark:"]

const log_template = "$# $# [$#] $#$#"
const log_template_std = "$# [$#] $#$#"
const log_template_std_trace = "$#, $#$#$#"
const log_template_bench = "$# $#\n$#\n" 
const log_template_std_bench = "$#\n$#\n" 

var thread  : Thread[void]
var channel : Channel[Msg]
var logs    : seq[Logger]

template DEBUG_MODE(code: untyped): untyped=
  when not defined(release) and not defined(danger):
    code

proc px_log_add(file:File) =
  logs.add Logger(file: file)
  channel.send Msg(kind: Update, u_logs: logs)

proc px_trace_send(lvl: uint8 = 0, args: varargs[string, `$`]) = 
  var msg = Msg(kind: Trace)
  msg.t_lvl = lvl
  if lvl == lv_debug:
    let tr = getStackTraceEntries()
    msg.t_stack = @[tr[tr.high-1]]
  else: msg.t_stack = getStackTraceEntries()
  for arg in args:
    msg.t_txt.add arg
    msg.t_txt.add "\n"
  channel.send msg
proc px_log_send(lvl: uint8 = 0, code: string, line: int, args: varargs[string, `$`]) = 
  var msg = Msg(kind: Write)
  msg.w_lvl = lvl
  msg.w_line = line
  msg.w_code = code
  for arg in args:
    msg.w_txt.add arg
    msg.w_txt.add "\n"
  channel.send msg

proc px_log_stop {.noconv.} =
  channel.send Msg(kind: Stop)
  joinThread thread
  close channel
  for log in logs:
    if log.file notin [stdout, stderr]:
      close log.file

proc px_log_execute() {.thread.} =
  var 
    logs = newSeq[Logger]()
    time_prev: Time
    time_str = ""
  while true:
    let msg = recv channel
    case msg.kind
    of Update:
      logs = msg.u_logs
    of Write:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"
      
      var text_log = log_template % [time_str,names[msg.w_lvl],msg.w_code,"",msg.w_txt]
      var text_log_std = log_template_std % [names_std[msg.w_lvl],msg.w_code,"",msg.w_txt]
      if msg.w_lvl == lv_bench: 
        text_log = log_template_bench % [time_str,names[msg.w_lvl],msg.w_txt]
        text_log_std = log_template_std_bench % [names_std[msg.w_lvl],msg.w_txt]
      
      for i in 1..logs.high:
        let log = logs[i].addr
        log.file.write text_log
        if channel.peek == 0:
          log.file.flushFile
      
      let log = logs[0].addr
      log.file.write text_log_std
      if channel.peek == 0:
          log.file.flushFile

    of Trace:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"
      let n = msg.t_stack[msg.t_stack.high]
      let tr = &"{n.filename} ({n.line})"
            
      var text_log = ""
      var text_log_std = ""
      var text_trace = ""
      
      if (msg.t_lvl == lv_trace):
        text_log = &"{time_str} {names[msg.t_lvl]} {msg.t_txt}"
        text_log_std = &"{names_std[msg.t_lvl]} {msg.t_txt}"
        var sym = "⯆"
        for i in 0..msg.t_stack.high-1:
          var n  =  msg.t_stack[i]
          if i==msg.t_stack.high-1:
            sym = "⯈"
          text_trace.add(&"{sym} {n.filename} ({n.line}) {n.procname}\n")
    
        text_log.add(text_trace)
        text_log_std.add(text_trace)
      else:
        text_log = &"{time_str} {names[msg.t_lvl]} {msg.t_txt}"
        text_log_std = &"{names_std[msg.t_lvl]} {msg.t_txt}"
        var n  =  msg.t_stack[0]
        text_trace.add(&"⯈ {n.filename} ({n.line}) {n.procname}\n")
    
        text_log.add(text_trace)
        text_log_std.add(text_trace)

      for i in 1..logs.high:
        let log = logs[i].addr
        log.file.write text_log
        if channel.peek == 0:
          log.file.flushFile
      
      let log = logs[0].addr
      log.file.write text_log_std
      if channel.peek == 0:
          log.file.flushFile

    of Stop:
      break 

  #var module = instantiationInfo()
  #echo module
  # var traces = getStackTraceEntries()
  # var sym = "⯆"
  # for i in 0..traces.high-1:
  #   var n  =  traces[i]
  #   if i==traces.high-1:
  #     sym = "⯈"
  #   echo &"{sym} {n.filename} ({n.line}) {n.procname} "
  # var trace_text = "  ⮡ "
  # for arg in args:
  #   trace_text.add(arg)

  # echo trace_text
proc add*(self: Log, file_name: string) =
  if file_name == "":
    echo "no file"
    return
  px_log_add(open(file_name,fmWrite))

template trace*(self: Log, args: varargs[string, `$`]) =
  DEBUG_MODE:
    px_trace_send(lv_trace, args)

template debug*(self: Log, args: varargs[string, `$`]) =
  DEBUG_MODE:
    px_trace_send(lv_debug, args)

template info*(self: Log, args: varargs[string, `$`]) =
    const module = instantiationInfo()
    px_log_send(lv_info, module.filename[0 .. ^5], module.line, args)

template warn*(self: Log, args: varargs[string, `$`]) =
    const module = instantiationInfo()
    px_log_send(lv_warn, module.filename[0 .. ^5], module.line, args)

template error*(self: Log, args: varargs[string, `$`]) =
    const module = instantiationInfo()
    px_log_send(lv_error, module.filename[0 .. ^5], module.line, args)

template benchmark*(self: Log, args: varargs[string, `$`]) =
    const module = instantiationInfo()
    px_log_send(lv_bench, "", 0, args)



open channel
thread.createThread px_log_execute

px_log_add(stdout)

addQuitProc px_log_stop