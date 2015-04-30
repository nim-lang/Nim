#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Timer support for the realtime GC. Based on
## `<https://github.com/jckarter/clay/blob/master/compiler/src/hirestimer.cpp>`_

type
  TTicks = distinct int64
  TNanos = int64

when defined(windows):

  proc QueryPerformanceCounter(res: var TTicks) {.
    importc: "QueryPerformanceCounter", stdcall, dynlib: "kernel32".}
  proc QueryPerformanceFrequency(res: var int64) {.
    importc: "QueryPerformanceFrequency", stdcall, dynlib: "kernel32".}

  proc getTicks(): TTicks {.inline.} =
    QueryPerformanceCounter(result)

  proc `-`(a, b: TTicks): TNanos =
    var frequency: int64
    QueryPerformanceFrequency(frequency)
    var performanceCounterRate = 1e+9'f64 / float64(frequency)

    result = TNanos(float64(a.int64 - b.int64) * performanceCounterRate)

elif defined(macosx):
  type
    TMachTimebaseInfoData {.pure, final, 
        importc: "mach_timebase_info_data_t", 
        header: "<mach/mach_time.h>".} = object
      numer, denom: int32

  proc mach_absolute_time(): int64 {.importc, header: "<mach/mach.h>".}
  proc mach_timebase_info(info: var TMachTimebaseInfoData) {.importc,
    header: "<mach/mach_time.h>".}

  proc getTicks(): TTicks {.inline.} =
    result = TTicks(mach_absolute_time())
  
  var timeBaseInfo: TMachTimebaseInfoData
  mach_timebase_info(timeBaseInfo)
    
  proc `-`(a, b: TTicks): TNanos =
    result = (a.int64 - b.int64)  * timeBaseInfo.numer div timeBaseInfo.denom

elif defined(posixRealtime):
  type
    TClockid {.importc: "clockid_t", header: "<time.h>", final.} = object

    TTimeSpec {.importc: "struct timespec", header: "<time.h>", 
               final, pure.} = object ## struct timespec
      tv_sec: int  ## Seconds. 
      tv_nsec: int ## Nanoseconds. 

  var
    CLOCK_REALTIME {.importc: "CLOCK_REALTIME", header: "<time.h>".}: TClockid

  proc clock_gettime(clkId: TClockid, tp: var TTimespec) {.
    importc: "clock_gettime", header: "<time.h>".}

  proc getTicks(): TTicks =
    var t: TTimespec
    clock_gettime(CLOCK_REALTIME, t)
    result = TTicks(int64(t.tv_sec) * 1000000000'i64 + int64(t.tv_nsec))

  proc `-`(a, b: TTicks): TNanos {.borrow.}

else:
  # fallback Posix implementation:  
  type
    Ttimeval {.importc: "struct timeval", header: "<sys/select.h>", 
               final, pure.} = object ## struct timeval
      tv_sec: int  ## Seconds. 
      tv_usec: int ## Microseconds. 
        
  proc posix_gettimeofday(tp: var Ttimeval, unused: pointer = nil) {.
    importc: "gettimeofday", header: "<sys/time.h>".}

  proc getTicks(): TTicks =
    var t: Ttimeval
    posix_gettimeofday(t)
    result = TTicks(int64(t.tv_sec) * 1000_000_000'i64 + 
                    int64(t.tv_usec) * 1000'i64)

  proc `-`(a, b: TTicks): TNanos {.borrow.}
