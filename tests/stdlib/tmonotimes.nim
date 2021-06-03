discard """
  targets: "c js"
  matrix: "; -d:danger" # for stricter tests
"""

#[
2021-06-03T02:07:14.3721337Z hostOS: linux, hostCPU: amd64, int: 8, float: 8, cpuEndian: littleEndian, cwd: /home/vsts/work/1/s
2021-06-03T02:32:49.9065595Z algo_CLOCK_MONOTONIC_RAW      1494125 0 0.117698076         
2021-06-03T02:32:49.9066026Z algo_rdtsc                    0       0 0.03613386900000001 
2021-06-03T02:32:49.9066472Z algo_CLOCK_MONOTONIC          1426367 0 0.115828089         
2021-06-03T02:32:49.9067205Z algo_CLOCK_REALTIME           1474289 0 0.115104388         
2021-06-03T02:32:49.9067645Z algo_CLOCK_PROCESS_CPUTIME_ID 2       2 2.69701975          
2021-06-03T02:32:49.9068084Z algo_CLOCK_THREAD_CPUTIME_ID  1       1 2.6568197280000003  
2021-06-03T02:32:49.9068611Z algo_CLOCK_REALTIME_COARSE    1999995 0 0.02563644399999987 
2021-06-03T02:32:49.9069047Z algo_CLOCK_MONOTONIC_COARSE   1999996 0 0.026368082999999487
2021-06-03T02:32:49.9069485Z algo_CLOCK_BOOTTIME           1474326 0 0.11490926300000037 


2021-06-03T02:08:01.1956120Z hostOS: linux, hostCPU: i386, int: 4, float: 8, cpuEndian: littleEndian, cwd: /home/vsts/work/1/s
2021-06-03T02:33:55.4234745Z algo_CLOCK_MONOTONIC_RAW      1068686 0 0.18872470300000002 
2021-06-03T02:33:55.4235229Z algo_rdtsc                    0       0 0.03184305499999998 
2021-06-03T02:33:55.4235711Z algo_CLOCK_MONOTONIC          1035172 0 0.19438633000000002 
2021-06-03T02:33:55.4236019Z algo_CLOCK_REALTIME           1092977 0 0.18653399799999998 
2021-06-03T02:33:55.4236321Z algo_CLOCK_PROCESS_CPUTIME_ID 1       1 2.451597024         
2021-06-03T02:33:55.4236606Z algo_CLOCK_THREAD_CPUTIME_ID  0       0 2.4446965379999996  
2021-06-03T02:33:55.4236906Z algo_CLOCK_REALTIME_COARSE    1999994 0 0.04769038100000067 
2021-06-03T02:33:55.4237204Z algo_CLOCK_MONOTONIC_COARSE   1999993 0 0.047188782000000096
2021-06-03T02:33:55.4237489Z algo_CLOCK_BOOTTIME           1089359 0 0.1881881940000003  

2021-06-03T02:07:52.3743090Z hostOS: macosx, hostCPU: amd64, int: 8, float: 8, cpuEndian: littleEndian, cwd: /Users/runner/work/1/s
2021-06-03T02:33:30.2895660Z algo_CLOCK_MONOTONIC_RAW        0       0 0.16474000000000003 
2021-06-03T02:33:30.2896160Z algo_rdtsc                      0       0 0.029745999999999995
2021-06-03T02:33:30.2896780Z algo_CLOCK_MONOTONIC            1878146 0 0.24800199999999997 
2021-06-03T02:33:30.2897270Z algo_CLOCK_REALTIME             1943107 0 0.11868500000000004 
2021-06-03T02:33:30.2897730Z algo_CLOCK_PROCESS_CPUTIME_ID   1156799 1 1.9283700000000001  
2021-06-03T02:33:30.2898250Z algo_CLOCK_THREAD_CPUTIME_ID    1       1 1.2801389999999997  
2021-06-03T02:33:30.2898740Z algo_CLOCK_UPTIME_RAW           0       0 0.13957499999999978 
2021-06-03T02:33:30.2899200Z algo_CLOCK_MONOTONIC_RAW_APPROX 1999992 0 0.07836700000000008 
2021-06-03T02:33:30.2899700Z algo_CLOCK_UPTIME_RAW_APPROX    1999939 0 0.07028299999999987 
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
