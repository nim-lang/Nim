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

template algoClock(clock): untyped = 
  var ts: Timespec
  discard clock_gettime(clock, ts)
  ts.tv_nsec.int64

template algo1(dummy: int): untyped = algoClock(CLOCK_MONOTONIC_RAW) # works?
template algo2(dummy: int): untyped =  algoClock(CLOCK_MONOTONIC)
template algo3(dummy: int): untyped =  algoClock(CLOCK_REALTIME)
template algo4(dummy: int): untyped =  algoClock(CLOCK_MONOTONIC_RAW_APPROX)
template algo5(dummy: int): untyped =  algoClock(CLOCK_UPTIME_RAW) # works?
template algo6(dummy: int): untyped =  algoClock(CLOCK_UPTIME_RAW_APPROX)
template algo7(dummy: int): untyped =  algoClock(CLOCK_PROCESS_CPUTIME_ID)
template algo8(dummy: int): untyped =  rdtsc() # works

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
  mainImpl(algo1)
  mainImpl(algo2)
  mainImpl(algo3)
  mainImpl(algo4)
  mainImpl(algo5)
  mainImpl(algo6)
  mainImpl(algo7)
  mainImpl(algo8)
  echo msg

main()
