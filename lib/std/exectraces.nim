#[
TODO:
options to enable/disable:
* line tracing
* function entry/exit tracing
* filter
* callbacks
* specify stacktrace

## links
dtrace
]#

type TraceAction* = enum
  kstart
  kstop

proc traceControl*(action: TraceAction) {.magic: "ExecTraceControl".} = discard
