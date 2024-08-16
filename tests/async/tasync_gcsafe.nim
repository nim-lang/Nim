discard """
  cmd: "nim c --threads:on $file"
  output: '''
1
2
3
'''
"""

doAssert compileOption("threads"), "this test will not do anything useful without --threads:on"

import asyncdispatch

var globalDummy: ref int
proc gcUnsafeProc() =
    if not globalDummy.isNil:
        echo globalDummy[]
    echo "1"

proc gcSafeAsyncProcWithNoAnnotation() {.async.} =
    echo "2"

proc gcSafeAsyncProcWithAnnotation() {.gcsafe, async.} =
    echo "3"

proc gcUnsafeAsyncProc() {.async.} =
    # We should be able to call gcUnsafe
    gcUnsafeProc()

    # We should be able to call async implicitly gcsafe
    await gcSafeAsyncProcWithNoAnnotation()

    # We should be able to call async explicitly gcsafe
    await gcSafeAsyncProcWithAnnotation()

waitFor gcUnsafeAsyncProc()
