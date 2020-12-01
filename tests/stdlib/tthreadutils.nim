discard """
joinable: false
"""

when defined nimTthreadutilsSub:
  import std/threadutils
  const N = 10
  var thr: array[N, Thread[int]]
  var count = 0
  proc threadFunc(a: int) {.thread.} =
    onceGlobal: count.inc
    doAssert count == 1
  proc main =
    for i in 0..<N:
      createThread(thr[i], threadFunc, i)
    joinThreads(thr)
  main()

else:
  from stdtest/specialpaths import buildDir
  import os, strformat
  proc main =
    # const N = 10000 # for manual testing
    const N = 100 # in CI, save some time
    const nim = getCurrentCompilerExe()
    const exe = buildDir / currentSourcePath.lastPathPart
    const file = currentSourcePath
    let cmd = fmt"{nim} c -d:nimTthreadutilsSub --threads -o:{exe} {file}"
    doAssert execShellCmd(cmd) == 0
    for i in 0..<N:
      let ret = execShellCmd(exe)
      doAssert ret == 0, $i
  main()
