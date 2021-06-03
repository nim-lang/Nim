discard """
  targets: "c js"
  matrix: "; -d:danger" # for stricter tests
"""

#[
2021-06-03T02:07:14.3721337Z hostOS: linux, hostCPU: amd64, int: 8, float: 8, cpuEndian: littleEndian, cwd: /home/vsts/work/1/s
2021-06-03T02:10:16.5852277Z algo_CLOCK_MONOTONIC_RAW: 66
2021-06-03T02:10:16.5852686Z algo_rdtsc: 0
2021-06-03T02:10:16.5852946Z algo_CLOCK_MONOTONIC: 68
2021-06-03T02:10:16.5853623Z algo_CLOCK_REALTIME: 49
2021-06-03T02:10:16.5854039Z algo_CLOCK_PROCESS_CPUTIME_ID: 0
2021-06-03T02:10:16.5854324Z algo_CLOCK_REALTIME_COARSE: 100
2021-06-03T02:10:16.5854606Z algo_CLOCK_MONOTONIC_COARSE: 100
2021-06-03T02:10:16.5854861Z algo_CLOCK_BOOTTIME: 53

2021-06-03T02:08:01.1956120Z hostOS: linux, hostCPU: i386, int: 4, float: 8, cpuEndian: littleEndian, cwd: /home/vsts/work/1/s
2021-06-03T02:10:50.8760877Z algo_CLOCK_MONOTONIC_RAW: 48
2021-06-03T02:10:50.8761117Z algo_rdtsc: 0
2021-06-03T02:10:50.8761361Z algo_CLOCK_MONOTONIC: 47
2021-06-03T02:10:50.8761602Z algo_CLOCK_REALTIME: 48
2021-06-03T02:10:50.8761876Z algo_CLOCK_PROCESS_CPUTIME_ID: 0
2021-06-03T02:10:50.8762162Z algo_CLOCK_REALTIME_COARSE: 100
2021-06-03T02:10:50.8762429Z algo_CLOCK_MONOTONIC_COARSE: 100
2021-06-03T02:10:50.8762698Z algo_CLOCK_BOOTTIME: 39

2021-06-03T02:07:52.3743090Z hostOS: macosx, hostCPU: amd64, int: 8, float: 8, cpuEndian: littleEndian, cwd: /Users/runner/work/1/s
2021-06-03T02:10:11.6100820Z algo_CLOCK_MONOTONIC_RAW: 0
2021-06-03T02:10:11.6101150Z algo_rdtsc: 0
2021-06-03T02:10:11.6101470Z algo_CLOCK_MONOTONIC: 93
2021-06-03T02:10:11.6101790Z algo_CLOCK_REALTIME: 97
2021-06-03T02:10:11.6102150Z algo_CLOCK_PROCESS_CPUTIME_ID: 49
2021-06-03T02:10:11.6102510Z algo_CLOCK_UPTIME_RAW: 0
2021-06-03T02:10:11.6102860Z algo_CLOCK_MONOTONIC_RAW_APPROX: 100
2021-06-03T02:10:11.6103250Z algo_CLOCK_UPTIME_RAW_APPROX: 100
]#


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

from std/times import cpuTime
import std/private/asciitables
import std/strutils

proc rdtsc(): uint64 {.importc.}

import posix
var CLOCK_MONOTONIC* {.importc, header: "<time.h>".}: cint
var CLOCK_MONOTONIC_RAW* {.importc, header: "<time.h>".}: cint
var CLOCK_REALTIME* {.importc, header: "<time.h>".}: cint
var CLOCK_MONOTONIC_RAW_APPROX* {.importc, header: "<time.h>".}: cint
var CLOCK_UPTIME_RAW* {.importc, header: "<time.h>".}: cint
var CLOCK_UPTIME_RAW_APPROX* {.importc, header: "<time.h>".}: cint
var CLOCK_PROCESS_CPUTIME_ID* {.importc, header: "<time.h>".}: cint
var CLOCK_THREAD_CPUTIME_ID* {.importc, header: "<time.h>".}: cint

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
template algo_CLOCK_THREAD_CPUTIME_ID(dummy: int): untyped =  algoClock(CLOCK_THREAD_CPUTIME_ID)

when defined linux:
  # https://linux.die.net/man/2/clock_gettime
  # https://man7.org/linux/man-pages/man3/clock_gettime.3.html
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
  let t1 = cpuTime()
  var c1 = 0
  var c2 = 0
  # let n = 100
  let n = 2000000
  for i in 0..<n:
    # this could fail with getTime instead of getMonoTime, as expected
    let a = algo(0)
    let b = algo(0)
    # echo (b - a, a, b)
    if b <= a: c2.inc
    if b < a: c1.inc
    # when defined(windows) and not defined(js):
    #   # bug #18158
    #   doAssert b >= a
    # else:
    #   doAssert b > a
    # doAssert b >= a, 
  let t2 = cpuTime()
  # let msgi = astToStr(algo) & ": " & $c2 & " " & $(t2 - t1)
  # let msgi = astToStr(algo) & " " & $(c1, c2, t2 - t1)
  let msgi = "$#\t$#\t$#\t$#" % [astToStr(algo), $c2, $c1, $(t2 - t1)]
  echo msgi
  msg.add msgi & "\n"

proc main =
  mainImpl(algo_CLOCK_MONOTONIC_RAW)
  mainImpl(algo_rdtsc)
  mainImpl(algo_CLOCK_MONOTONIC)
  mainImpl(algo_CLOCK_REALTIME)
  mainImpl(algo_CLOCK_PROCESS_CPUTIME_ID)
  mainImpl(algo_CLOCK_THREAD_CPUTIME_ID)
  when defined linux:
    mainImpl(algo_CLOCK_REALTIME_COARSE)
    mainImpl(algo_CLOCK_MONOTONIC_COARSE)
    mainImpl(algo_CLOCK_BOOTTIME)
  else:
    mainImpl(algo_CLOCK_UPTIME_RAW)
    mainImpl(algo_CLOCK_MONOTONIC_RAW_APPROX)
    mainImpl(algo_CLOCK_UPTIME_RAW_APPROX)
  echo "----------------"
  echo msg.alignTable

main()
