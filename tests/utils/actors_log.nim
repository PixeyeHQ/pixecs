## Created by Pixeye | dev@pixeye.com   
##
## This module is used for async logging.
{.used.}

import times
import strutils
import strformat
import system

type Logger* = object
  file: File

type MsgKind = enum
  Write,Trace,Update,Stop

type Msg = object
  case kind: MsgKind
  of Write:
    w_txt  : string
    w_lvl  : uint8
  of Trace:
    t_stack: seq[StackTraceEntry]
    t_txt  : string
    t_lvl  : uint8
  of Update:
    u_logs: ptr seq[Logger]
    u_log_std : Logger
  of Stop:
    nil

const lv_trace = 0'u8
const lv_debug = 1'u8
const lv_info  = 2'u8
const lv_warn  = 3'u8
const lv_error = 4'u8
const lv_bench = 5'u8

const names_std: array[6, string] = ["\e[0;32mTrace:\e[39m","\e[0;32mDebug:\e[39m","\e[0;36m Info:\e[39m","\e[0;33m Warn:\e[39m","\e[0;31mError:\e[39m", "\e[0;36mBenchmark:\e[39m"]
const names    : array[6, string] = ["Trace", "Debug"," Info"," Warn","Error", "Benchmark"]

const log_template = "$# $# $#$#"
const log_template_std = "$# $#$#"
const log_template_bench = "$# $#\n$#\n" 
const log_template_std_bench = "$#\n$#\n" 

var thread  : Thread[void]
var channel : Channel[Msg]
var logs    : seq[Logger]
var log_std : Logger

var t1* = 0.0f
template DEBUG_MODE(code: untyped): untyped=
  when not defined(release) and not defined(danger):
    code



proc px_trace_send(lvl: uint8 = 0, args: varargs[string, `$`]) = 
  var t_msg = Msg(kind: Trace)
  t_msg.t_lvl = lvl
  if lvl == lv_debug:
    let tr = getStackTraceEntries()
    t_msg.t_stack = @[tr[tr.high-1]]
  else: t_msg.t_stack = getStackTraceEntries()
  t_msg.t_txt.setLen(0)
  for arg in args:
    t_msg.t_txt.add arg
  channel.send t_msg

proc px_log_send*(lvl: uint8 = 0, args: varargs[string, `$`]) = 
  var w_msg = Msg(kind: Write)
  w_msg.w_lvl = lvl
  w_msg.w_txt.setLen(0)
  for arg in args:
    w_msg.w_txt.add arg
    w_msg.w_txt.add "\n"
  channel.send w_msg

proc px_log_stop {.noconv.} =
  channel.send Msg(kind: Stop)
  joinThread thread
  close channel
  for log in logs:
    if log.file notin [stdout, stderr]:
      close log.file

proc px_log_execute() {.thread.} =
  var 
    logs : seq[Logger]
    log_std : Logger
    time_prev: Time
    time_str = ""
  while true:
    let msg = recv channel
    case msg.kind
    of Update:
      logs = msg.u_logs[]
      log_std = msg.u_log_std
    of Write:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"
      var text_log = ""
      var text_log_std =""
      if msg.w_lvl == lv_bench: 
        text_log = log_template_bench % [time_str,names[msg.w_lvl],msg.w_txt]
        text_log_std = log_template_std_bench % [names_std[msg.w_lvl],msg.w_txt]
      else:
        text_log = log_template % [time_str,names[msg.w_lvl],"",msg.w_txt]
        text_log_std= log_template_std % [names_std[msg.w_lvl],"",msg.w_txt]

      for i in 0..logs.high:
        let log = logs[i].addr
        log.file.write text_log
        if channel.peek == 0:
          log.file.flushFile
      
      if not log_std.file.isNil:
        log_std.file.write text_log_std
        if channel.peek == 0:
            log_std.file.flushFile

    of Trace:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"

      var text_log = ""
      var text_log_std = ""
      var text_trace = ""
 
      if (msg.t_lvl == lv_trace or msg.t_lvl == lv_error):
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
        text_log = &"{time_str} {names[msg.t_lvl]} {msg.t_txt} "
        text_log_std = &"{names_std[msg.t_lvl]} {msg.t_txt} "
        var n  =  msg.t_stack[0]
        text_trace.add(&"⯈ {n.filename} ({n.line}) {n.procname}\n")

        text_log.add(text_trace)
        text_log_std.add(text_trace)

      for i in 0..logs.high:
        let log = logs[i].addr
        log.file.write text_log
        if channel.peek == 0:
          log.file.flushFile
      
      if not log_std.file.isNil:
        log_std.file.write text_log_std
        if channel.peek == 0:
            log_std.file.flushFile

    of Stop:
      break 

template px_log_bench*(args: varargs[string, `$`]) =
    px_log_send(lv_bench, args)

proc logAdd*(file:File) =
  if file == stdout:
    log_std = Logger(file: file)
  else:
    logs.add Logger(file: file)
  channel.send Msg(kind: Update, u_logs: logs.addr, u_log_std: log_std)

proc logAdd*(file_name: string) =
  if file_name == "":
    echo "no file"
    return
  logAdd(open(file_name,fmWrite))

template log*(args: varargs[string, `$`]) =
  DEBUG_MODE:
    px_trace_send(lv_debug, args)

template logTrace*(args: varargs[string, `$`]) =
  DEBUG_MODE:
    px_trace_send(lv_trace, args)

template logInfo*(args: varargs[string, `$`]) =
    px_log_send(lv_info,  args)

template logWarn*(args: varargs[string, `$`]) =
    px_log_send(lv_warn, args)

template logError*( args: varargs[string, `$`]) =
    px_trace_send(lv_error, args)

open channel
createThread thread, px_log_execute
addQuitProc px_log_stop