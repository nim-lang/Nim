discard """
joinable: false
"""

#[
run with: `-d:nimTthreadutilsNum:10000` for stress testing
]#

when defined nimTthreadutilsSub:
  import std/threadutils
  from std/os import sleep

  block: # tests thread safety: bug #8895
    var thr: array[10, Thread[int]]
    var count = 0
    proc threadFunc(a: int) {.thread.} =
      onceGlobal: count.inc
      doAssert count == 1
    proc main =
      for i, t in mpairs(thr):
        t.createThread(threadFunc, i)
      joinThreads(thr)
    main()

  block: # tests that each `onceGlobal` has its own lock
    var thr: array[2, Thread[void]]
    var count = 0
    var count2 = 0
    proc threadFunc() {.thread.} =
      proc fnAux(m: int) =
        for j in 0..<3:
          onceGlobal:
            while count2 == 0: sleep(10)
            count.inc
        doAssert count == 1
        if m > 0: fnAux(m-1) # test for re-entrant code
      fnAux(3)
    for t in mitems(thr): t.createThread threadFunc
    for j in 0..<3:
      onceGlobal: # no deadlock, this has its own lock
        sleep(10)
        count2.inc
    doAssert count2 == 1
    joinThreads(thr)

  block: # tests `retryOnFailure` behavior
    const N = 10
    type Input = tuple[tid: int, retryOnFailure: bool]
    var thr: array[N, Thread[Input]]
    var count = 0
    proc threadFunc(input: Input) {.thread.} =
      let winner = N-1
      if input.tid == winner:
        # losers go first and will raise ValueError
        sleep(1)
      try:
        onceGlobal(retryOnFailure = input.retryOnFailure):
          if input.tid != winner:
            raise newException(ValueError, "bad")
          count.inc
      except:
        discard
    for retryOnFailure in [true, false]:
      count = 0
      for i, t in mpairs(thr): t.createThread(threadFunc, (i, retryOnFailure))
      joinThreads(thr)
      if retryOnFailure:
        doAssert count == 1
      else:
        doAssert count == 0

else:
  from stdtest/specialpaths import buildDir
  import os, strformat
  proc main =
    block: # onceGlobal
      const nim = getCurrentCompilerExe()
      const exe = buildDir / currentSourcePath.lastPathPart
      const file = currentSourcePath
      let cmd = fmt"{nim} c -d:nimTthreadutilsSub --hints:off --threads -o:{exe} {file}"
      doAssert execShellCmd(cmd) == 0
      const nimTthreadutilsNum {.intdefine.} = 100 # in CI, save some time
      for i in 0..<nimTthreadutilsNum:
        let ret = execShellCmd(exe)
        doAssert ret == 0, $i

  main()

  import std/threadutils

  block: # `onceThread` basic example
    var count = 0
    for i in 0..<10:
      onceThread:
        count.inc
    doAssert count == 1

    onceThread:
      count.inc
    doAssert count == 2

  block: # `onceThread`, test for re-entrant code
    var count = 0
    var countCT {.compileTime.} = 0
    proc fn(n: int) =
      for i in 0..<3:
        onceThread:
          when nimvm:
            countCT.inc
          else:
            count.inc
      if n > 1:
        fn(n-1)
    proc main() =
      fn(5)
      fn(4)
      when nimvm:
        echo countCT
        # doAssert countCT == 1 # fails
      else:
        doAssert count == 1
    # static: main() # xxx support vm + js
    main()
