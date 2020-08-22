{.used.}

import times
import strutils
import typeinfo
import system


type Log = object
  file: File
type MessageKind = enum
  write,update,stop
type Message = object
  case kind: MessageKind
  of write:
    traceText: string
    text: string
    mode: int
    external: bool
  of update:
    logs: seq[Log]
  of stop:
    nil


const #@templates
  names_stdout: array[6, string] = ["\e[0;32mDebug:\e[39m","\e[0;34mInfo: \e[39m","\e[0;33mWarn: \e[39m","\e[0;31mError:\e[39m","\e[0;35mFatal\e[39m", "\e[0;34mBenchmark:\e[39m"]
  names: array[6, string] = ["Debug:","Info: ","Warn: ","Error:","Fatal:", "Benchmark:"]
  log_template_stdout = "[$#] $# $#$#" 
  log_template_bench_stdout = "[$#] $#\n$#\n" 
  log_template = "[$#] $# $#$#"
  log_template_bench = "[$#] $#\n$#\n"  
  
  debug* = 0'i8
  info* = 1'i8
  warn* = 2'i8
  error* = 3'i8
  fatal* = 4'i8
  benchmark* = 5'i8


var thread  : Thread[void]
var channel : Channel[Message]
  
var log_mask    = {debug..benchmark}
var logs        = newSeq[Log]()
var log_console = Log(file: stdout)


proc logSetMask*(mask: set[int8]) =
  log_mask = mask
  discard

proc logAdd*(file:File) =
  logs.add Log(file: file)
  channel.send Message(kind: update, logs: logs)

proc logAdd*(file_name: string) =
  if file_name == "":
    echo "no file"
    return
  logAdd(open(file_name,fmWrite))

template log*(level: int8 = debug, args: varargs[string, `$`]) = 
    if level in log_mask:
      var msg = Message(kind: write, traceText: "", mode: level, external : false)
      for arg in args:
        msg.text.add arg
        msg.text.add "\n"
      channel.send msg

template log*(args: varargs[string, `$`]) =
  log(debug,args)

proc trace*(level: int8 = debug, args: varargs[string, `$`]) {.inline.} =
  if level in log_mask:
    var traces = getStackTraceEntries()
    var traceNode = traces[traces.high-1]
    var fname = newString(traceNode.filename.len)
    var line = intToStr(traceNode.line)

    copyMem(addr(fname[0]), traceNode.filename, traceNode.filename.len)

    var traceString = fname & "(" & line & ")"

    var msg = Message(kind: write, traceText: traceString, mode: level, external : false)
    for arg in args:
      msg.text.add " "
      msg.text.add arg
      msg.text.add "\n"
    channel.send msg

template trace*(args: varargs[string, `$`]) =
  trace(debug,args)

proc logExternal*(level: int8 = debug, args: varargs[string, `$`]) {.inline.} = 
    if level in log_mask:
      var traces = getStackTraceEntries()
      var traceNode = traces[traces.high-1]
      var fname = newString(traceNode.filename.len)
      var line = intToStr(traceNode.line)
      copyMem(addr(fname[0]), traceNode.filename, traceNode.filename.len)
      var traceString = fname & "(" & line & ")"
      var msg = Message(kind: write, traceText: traceString, mode: level, external : true)
      for arg in args:
        msg.text.add " "
        msg.text.add arg
        msg.text.add "\n"
      channel.send msg

proc logThread {.thread.} =
  var 
    logs = newSeq[Log]()
    time_prev: Time
    time_str = ""
  while true:
    let msg = recv channel
    case msg.kind
    of write:
      let time_new = getTime()
      if time_new != time_prev:
        time_prev = time_new
        time_str = local(time_new).format "HH:mm:ss"

      var text_log = ""
      var text_log_stdout = ""
      if msg.mode == benchmark:
        text_log = log_template_bench % [time_str,names[msg.mode],msg.text]
        text_log_stdout = log_template_bench_stdout % [time_str,names_stdout[msg.mode],msg.text]
      else:
        text_log = log_template % [time_str,names[msg.mode],msg.traceText,msg.text]
        text_log_stdout = log_template_stdout % [time_str,names_stdout[msg.mode],msg.traceText,msg.text]
      for log in logs:
        log.file.write  text_log
        if channel.peek == 0:
          log.file.flushFile
      if not msg.external:
        log_console.file.write text_log_stdout
        if channel.peek == 0:
          log_console.file.flushFile

    of update:
      logs = msg.logs
    of stop:
      break 
  
proc logStop {.noconv.} =
  channel.send Message(kind: stop)
  joinThread thread
  close channel

  for log in logs:
    if log.file notin [stdout, stderr]:
      close log.file


open channel
thread.createThread logThread
addQuitProc logStop
