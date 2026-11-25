discard """
  matrix: "--profiler:on --stackTrace:on; --profiler:on --stackTrace:on --mm:refc"
  output: '''
true
writing profile_results.txt...
... done'''
"""

# bug #25466: the profiler hook called profiled code (cstring `==`, `hash`)
# and so re-entered itself until the stack overflowed

import nimprof
import std/os

setSamplingFrequency(0) # call the hook on every profiled call

proc fib(n: int): int =
  if n < 2: n else: fib(n-1) + fib(n-2)

var s = 0
for i in 0 ..< 10:
  s += fib(18)
disableProfiling()
echo s > 0
# do not leave 'profile_results.txt' in the test directory:
setCurrentDir(getTempDir())
