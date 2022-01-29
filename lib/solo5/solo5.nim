## Solo5 glue.
# (c) 2022 Emery Heminyway

{.pragma: solo5header, header: "solo5.h".}
{.pragma: solo5, importc: "solo5_$1", solo5header.}

type
  Result* {.importc: "solo5_result_t", solo5header.} = enum
    SOLO5_R_OK,
    SOLO5_R_AGAIN,
    SOLO5_R_EINVAL,
    SOLO5_R_EUNSPEC

  StartInfo* {.importc: "solo5_start_info", solo5header.} = object
    cmdline*: cstring
    heap_start*: pointer
    heap_size*: csize_t

  Time* = distinct uint64
    ## Type for time values, with nanosecond precision.

  Handle* = distinct uint64
    ## Type for I/O handles.

  HandleSet* = distinct uint64
    ## Type for sets of up to 64 I/O handles.

proc `<`*(x, y: Time): bool {.borrow.}
proc `+`*(x, y: Time): Time {.borrow.}

proc `==`*(x, y: Handle): bool {.borrow.}
proc `$`*(x: Handle): string {.borrow.}

const
  SOLO5_EXIT_SUCCESS* = 0
  SOLO5_EXIT_FAILURE* = 1
  SOLO5_EXIT_ABORT* = 255

let nim_start_info* {.importc: "nim_start_info", nodecl.}: ptr StartInfo

proc exit*(status: cint) {.solo5, noreturn.}

proc abort*() {.solo5, noreturn.}

proc set_tls_base*(base: pointer): Result {.solo5.}

proc clock_monotonic*(): Time {.solo5.}

proc clock_wall*(): Time {.solo5.}

proc `yield`*(deadline: Time; ready_set: ptr HandleSet = nil) {.solo5, tags: [TimeEffect].}

proc console_write*(buf: cstring; size: csize_t) {.solo5, tags: [WriteIOEffect].}

proc console_write*(s: static[string]) = console_write(s.cstring, s.len)
