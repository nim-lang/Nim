discard """
  cmd: "nim $target --hints:on --define:useNimRtl $options $file"
  output: '''
foreign thread 7
main'''
  disabled: windows
"""

# A thread that Nim did not start calls setupForeignThreadGc before it uses
# Nim. With nimrtl that did nothing, so the thread had no region of nimrtl's
# allocator, and its first allocation crashed.

import std/posix

proc foreign(arg: pointer): pointer {.noconv.} =
  setupForeignThreadGc()
  echo "foreign thread ", cast[int](arg)
  tearDownForeignThreadGc()
  nil

var t: Pthread
doAssert pthread_create(addr t, nil, foreign, cast[pointer](7)) == 0
doAssert pthread_join(t, nil) == 0
echo "main"
