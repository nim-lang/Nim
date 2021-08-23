##[
Experimental API, subject to change
]##

#[
Future work:
* convert ticks to time; see some approaches here: https://quick-bench.com/q/WcbqUWBCoNBJvCP4n8h3kYfZDXU
* provide feature detection to test whether the CPU supports it (on linux, via /proc/cpuinfo)

## further links
* https://www.intel.com/content/dam/www/public/us/en/documents/white-papers/ia-32-ia-64-benchmark-code-execution-paper.pdf
* https://gist.github.com/savanovich/f07eda9dba9300eb9ccf
* https://developers.redhat.com/blog/2016/03/11/practical-micro-benchmarking-with-ltrace-and-sched#
]#

when defined(js):
  proc getCpuTicksImpl(): int64 =
    ## Returns ticks in nanoseconds.
    # xxx consider returning JsBigInt instead of float
    when defined(nodejs):
      {.emit: """
      let process = require('process');
      `result` = Number(process.hrtime.bigint());
      """.}
    else:
      proc jsNow(): int64 {.importjs: "window.performance.now()".}
      result = jsNow() * 1_000_000
else:
  const header =
    when defined(posix): "<x86intrin.h>"
    else: "<intrin.h>"
  proc getCpuTicksImpl(): uint64 {.importc: "__rdtsc", header: header.}

template getCpuTicks*(): int64 =
  ## Returns number of CPU ticks as given by `RDTSC` instruction.
  ## Unlike `std/monotimes.ticks`, this gives a strictly monotonic counter
  ## and has higher resolution and lower overhead,
  ## allowing to measure individual instructions (corresponding to time offsets in
  ## the nanosecond range).
  ##
  ## Note that the CPU may reorder instructions.
  runnableExamples:
    for i in 0..<100:
      let t1 = getCpuTicks()
      # code to benchmark can go here
      let t2 = getCpuTicks()
      assert t2 > t1
  cast[int64](getCpuTicksImpl())

template toInt64(a, b): untyped =
  cast[int64](cast[uint](a) or (cast[uint](d) shl 32))

proc getCpuTicksStart*(): int64 {.inline.} =
  ## Variant of `getCpuTicks` which uses the `RDTSCP` instruction. Compared to
  ## `getCpuTicks`, this avoids introducing noise in the measurements caused by
  ## CPU instruction reordering, and can result in more deterministic results,
  ## at the expense of extra overhead and requiring asymetric start/stop APIs.
  runnableExamples:
    var a = 0
    for i in 0..<100:
      let t1 = getCpuTicksStart()
      # code to benchmark can go here
      let t2 = getCpuTicksEnd()
      assert t2 > t1, $(t1, t2)
  when nimvm: result = getCpuTicks()
  else:
    when defined(js): result = getCpuTicks()
    else:
      var a {.noinit.}: cuint
      var d {.noinit.}: cuint
      # See https://developers.redhat.com/blog/2016/03/11/practical-micro-benchmarking-with-ltrace-and-sched
      {.emit:"""
      asm volatile("cpuid" ::: "%rax", "%rbx", "%rcx", "%rdx");
      asm volatile("rdtsc" : "=a" (a), "=d" (d)); 
      """.}
      result = toInt64(a, b)

proc getCpuTicksEnd*(): int64 {.inline.} =
  ## See `getCpuTicksStart`.
  when nimvm: result = getCpuTicks()
  else:
    when defined(js): result = getCpuTicks()
    else:
      var a {.noinit.}: cuint
      var d {.noinit.}: cuint
      {.emit:"""
      asm volatile("rdtscp" : "=a" (a), "=d" (d)); 
      asm volatile("cpuid" ::: "%rax", "%rbx", "%rcx", "%rdx");
      """.}
      result = toInt64(a, b)
