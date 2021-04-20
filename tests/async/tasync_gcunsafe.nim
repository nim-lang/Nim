discard """
  errormsg: "'anotherGCSafeAsyncProcIter' is not GC-safe as it calls 'asyncGCUnsafeProc'"
  cmd: "nim c --threads:on $file"
  file: "asyncmacro.nim"
"""

doAssert compileOption("threads"), "this test will not do anything useful without --threads:on"

import asyncdispatch

var globalDummy: ref int
proc gcUnsafeProc() =
    if not globalDummy.isNil:
        echo globalDummy[]

proc asyncExplicitlyGCSafeProc() {.gcsafe, async.} =
    echo "hi"

proc asyncImplicitlyGCSafeProc() {.async.} =
    echo "hi"

proc asyncGCUnsafeProc() {.async.} =
    gcUnsafeProc()

proc anotherGCSafeAsyncProc() {.async, gcsafe.} =
    # We should be able to call other gcsafe procs
    await asyncExplicitlyGCSafeProc()
    await asyncImplicitlyGCSafeProc()
    # But we can't call gcunsafe procs
    await asyncGCUnsafeProc()
