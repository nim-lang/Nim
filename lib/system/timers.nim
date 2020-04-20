#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Timer support for the realtime GC. Based on
## `<https://github.com/jckarter/clay/blob/master/compiler/hirestimer.cpp>`_

type
  Ticks = distinct int64
  Nanos = int64

when defined(windows):

  proc QueryPerformanceCounter(res: var Ticks) {.
    importc: "QueryPerformanceCounter", stdcall, dynlib: "kernel32".}
  proc QueryPerformanceFrequency(res: var int64) {.
    importc: "QueryPerformanceFrequency", stdcall, dynlib: "kernel32".}

  proc getTicks(): Ticks {.inline.} =
    QueryPerformanceCounter(result)

  proc `-`(a, b: Ticks): Nanos =
    var frequency: int64
    QueryPerformanceFrequency(frequency)
    var performanceCounterRate = 1e+9'f64 / float64(frequency)

    result = Nanos(float64(a.int64 - b.int64) * performanceCounterRate)

elif defined(macosx) and not defined(emscripten):
  type
    MachTimebaseInfoData {.pure, final,
        importc: "mach_timebase_info_data_t",
        header: "<mach/mach_time.h>".} = object
      numer, denom: int32 # note: `uint32` in sources

  proc mach_absolute_time(): uint64 {.importc, header: "<mach/mach_time.h>".}
  proc mach_timebase_info(info: var MachTimebaseInfoData) {.importc,
    header: "<mach/mach_time.h>".}

  proc getTicks(): Ticks {.inline.} =
    result = Ticks(mach_absolute_time())

  var timeBaseInfo: MachTimebaseInfoData
  mach_timebase_info(timeBaseInfo)

  proc `-`(a, b: Ticks): Nanos =
    result = (a.int64 - b.int64) * timeBaseInfo.numer div timeBaseInfo.denom

elif defined(posixRealtime):
  type
    Clockid {.importc: "clockid_t", header: "<time.h>", final.} = object

    TimeSpec {.importc: "struct timespec", header: "<time.h>",
               final, pure.} = object ## struct timespec
      tv_sec: int  ## Seconds.
      tv_nsec: int ## Nanoseconds.

  var
    CLOCK_REALTIME {.importc: "CLOCK_REALTIME", header: "<time.h>".}: Clockid

  proc clock_gettime(clkId: Clockid, tp: var Timespec) {.
    importc: "clock_gettime", header: "<time.h>".}

  proc getTicks(): Ticks =
    var t: Timespec
    clock_gettime(CLOCK_REALTIME, t)
    result = Ticks(int64(t.tv_sec) * 1000000000'i64 + int64(t.tv_nsec))

  proc `-`(a, b: Ticks): Nanos {.borrow.}

else:
  # fallback Posix implementation:
  when not declared(Time):
    when defined(linux):
      type Time = clong
    else:
      type Time = int

  type
    Timeval {.importc: "struct timeval", header: "<sys/select.h>",
               final, pure.} = object ## struct timeval
      tv_sec: Time  ## Seconds.
      tv_usec: clong ## Microseconds.

  proc posix_gettimeofday(tp: var Timeval, unused: pointer = nil) {.
    importc: "gettimeofday", header: "<sys/time.h>".}

  proc getTicks(): Ticks =
    var t: Timeval
    posix_gettimeofday(t)
    result = Ticks(int64(t.tv_sec) * 1000_000_000'i64 +
                    int64(t.tv_usec) * 1000'i64)

  proc `-`(a, b: Ticks): Nanos {.borrow.}
