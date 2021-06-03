discard """
  targets: "c js"
  matrix: "; -d:danger" # for stricter tests
"""

# import std/[monotimes, times]

{.emit:"""
#include <stdint.h>

//  Windows
#ifdef _WIN32

#include <intrin.h>
inline uint64_t rdtsc(){
    return __rdtsc();
}

//  Linux/GCC
#else

inline uint64_t rdtsc(){
    unsigned int lo,hi;
    __asm__ __volatile__ ("rdtsc" : "=a" (lo), "=d" (hi));
    return ((uint64_t)hi << 32) | lo;
}

#endif
""".}

proc rdtsc(): uint64 {.importc.}

import posix
var CLOCK_MONOTONIC* {.importc, header: "<time.h>".}: cint
var CLOCK_MONOTONIC_RAW* {.importc, header: "<time.h>".}: cint
var CLOCK_REALTIME* {.importc, header: "<time.h>".}: cint
var CLOCK_MONOTONIC_RAW_APPROX* {.importc, header: "<time.h>".}: cint
var CLOCK_UPTIME_RAW* {.importc, header: "<time.h>".}: cint
var CLOCK_UPTIME_RAW_APPROX* {.importc, header: "<time.h>".}: cint
var CLOCK_PROCESS_CPUTIME_ID* {.importc, header: "<time.h>".}: cint

when defined linux:
  var CLOCK_REALTIME_COARSE* {.importc, header: "<time.h>".}: cint
  var CLOCK_MONOTONIC_COARSE* {.importc, header: "<time.h>".}: cint
  var CLOCK_BOOTTIME* {.importc, header: "<time.h>".}: cint

template algoClock(clock): untyped = 
  var ts: Timespec
  discard clock_gettime(clock, ts)
  ts.tv_nsec.int64

template algo_CLOCK_MONOTONIC_RAW(dummy: int): untyped = algoClock(CLOCK_MONOTONIC_RAW) # works on osx
template algo_CLOCK_MONOTONIC(dummy: int): untyped =  algoClock(CLOCK_MONOTONIC)
template algo_rdtsc(dummy: int): untyped =  rdtsc() # works on osx
template algo_CLOCK_REALTIME(dummy: int): untyped =  algoClock(CLOCK_REALTIME)
template algo_CLOCK_PROCESS_CPUTIME_ID(dummy: int): untyped =  algoClock(CLOCK_PROCESS_CPUTIME_ID)

when defined linux:
  # https://linux.die.net/man/2/clock_gettime
  template algo_rdtsc(dummy: int): untyped =  rdtsc()

  template algo_CLOCK_REALTIME_COARSE(dummy: int): untyped =  algoClock(CLOCK_REALTIME_COARSE)
  template algo_CLOCK_MONOTONIC_COARSE(dummy: int): untyped =  algoClock(CLOCK_MONOTONIC_COARSE)
  template algo_CLOCK_BOOTTIME(dummy: int): untyped =  algoClock(CLOCK_BOOTTIME)
else:
  template algo_CLOCK_UPTIME_RAW_APPROX(dummy: int): untyped =  algoClock(CLOCK_UPTIME_RAW_APPROX)
  template algo_CLOCK_MONOTONIC_RAW_APPROX(dummy: int): untyped =  algoClock(CLOCK_MONOTONIC_RAW_APPROX)
  template algo_CLOCK_UPTIME_RAW(dummy: int): untyped =  algoClock(CLOCK_UPTIME_RAW) # works on osx

var msg = ""
template mainImpl(algo) = 
  var c2 = 0
  let n = 100
  for i in 0..<n:
    # this could fail with getTime instead of getMonoTime, as expected
    let a = algo(0)
    let b = algo(0)
    echo (b - a, a, b)
    if b <= a: c2.inc
    # when defined(windows) and not defined(js):
    #   # bug #18158
    #   doAssert b >= a
    # else:
    #   doAssert b > a
    doAssert b >= a
  let msgi = astToStr(algo) & ": " & $c2
  echo msgi
  msg.add msgi & "\n"

proc main =
  mainImpl(algo_CLOCK_MONOTONIC_RAW)
  mainImpl(algo_rdtsc)
  mainImpl(algo_CLOCK_MONOTONIC)
  mainImpl(algo_CLOCK_REALTIME)
  mainImpl(algo_CLOCK_PROCESS_CPUTIME_ID)
  when defined linux:
    mainImpl(algo_CLOCK_REALTIME_COARSE)
    mainImpl(algo_CLOCK_MONOTONIC_COARSE)
    mainImpl(algo_CLOCK_BOOTTIME)
  else:
    mainImpl(algo_CLOCK_UPTIME_RAW)
    mainImpl(algo_CLOCK_MONOTONIC_RAW_APPROX)
    mainImpl(algo_CLOCK_UPTIME_RAW_APPROX)
  echo "----------------"
  echo msg

main()
