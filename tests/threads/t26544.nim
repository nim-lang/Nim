discard """
  matrix: "--mm:orc; --mm:refc"
  output: '''
createThread failed
running: false'''
"""

# bug #26544: `running()` stayed true after `createThread` failed

import std/typedthreads

proc work() {.thread.} = discard

var t: Thread[void]

when defined(linux) and sizeof(int) == 8: # thread stacks are 2MB here
  import std/[posix, strutils]

  var RLIMIT_AS {.importc, header: "<sys/resource.h>".}: cint

  # leave too little address space for a thread stack:
  let pages = readFile("/proc/self/statm").split(' ')[0].parseInt
  var lim: RLimit
  doAssert getrlimit(RLIMIT_AS, lim) == 0
  lim.rlim_cur = pages * sysconf(SC_PAGESIZE) + 1024 * 1024
  doAssert setrlimit(RLIMIT_AS, lim) == 0
  try:
    createThread(t, work)
    joinThread(t)
  except ResourceExhaustedError:
    echo "createThread failed"
else:
  echo "createThread failed"
echo "running: ", t.running
