#[
TODO:
options to enable/disable:
* line tracing
* function entry/exit tracing
* filter
* callbacks
* specify stacktrace
* allow customizing what gets traced without having to edit sources, eg using a whitelist of fully qualified symbols

## links
dtrace
]#

type TraceAction* = enum
  # kdefault
  kstart
  kstop

proc traceControl*(action: TraceAction) {.magic: "ExecTraceControl", compileTime.} = discard
