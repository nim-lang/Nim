discard """
  matrix: "--threads"
  joinable: false
  target: "c cpp"
"""

import os, system

proc c_getenv(env: cstring): cstring {.importc: "getenv", header: "<stdlib.h>".}
var thr: Thread[void]
proc threadFunc {.thread.} =
  putEnv("foo", "fooVal2")

block:
  putEnv("foo", "fooVal1")
  echo getEnv("foo")
  createThread(thr, threadFunc)
  joinThreads(thr)
  doAssert getEnv("foo") == $c_getenv("foo")

block:
  doAssertRaises(OSError): delEnv("foo=bar")