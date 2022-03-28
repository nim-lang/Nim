discard """
  matrix: "--threads"
  joinable: false
  targets: "c js cpp"
"""

import std/os
from std/sequtils import toSeq
import stdtest/testutils

template main =
  block: # delEnv, existsEnv, getEnv, envPairs
    for val in ["val", ""]: # ensures empty val works too
      const key = "NIM_TESTS_TOSENV_KEY"
      doAssert not existsEnv(key)

      putEnv(key, "tempval")
      doAssert existsEnv(key)
      doAssert getEnv(key) == "tempval"

      putEnv(key, val) # change a key that already exists
      doAssert existsEnv(key)
      doAssert getEnv(key) == val

      doAssert (key, val) in toSeq(envPairs())
      delEnv(key)
      doAssert (key, val) notin toSeq(envPairs())
      doAssert not existsEnv(key)
      delEnv(key) # deleting an already deleted env var
      doAssert not existsEnv(key)

    block:
      doAssert getEnv("NIM_TESTS_TOSENV_NONEXISTENT", "") == ""
      doAssert getEnv("NIM_TESTS_TOSENV_NONEXISTENT", " ") == " "
      doAssert getEnv("NIM_TESTS_TOSENV_NONEXISTENT", "defval") == "defval"

    whenVMorJs: discard # xxx improve
    do:
      doAssertRaises(OSError, putEnv("NIM_TESTS_TOSENV_PUT=DUMMY_VALUE", "NEW_DUMMY_VALUE"))
      doAssertRaises(OSError, putEnv("", "NEW_DUMMY_VALUE"))
      doAssert not existsEnv("")
      doAssert not existsEnv("NIM_TESTS_TOSENV_PUT=DUMMY_VALUE")
      doAssert not existsEnv("NIM_TESTS_TOSENV_PUT")

static: main()
main()

when not defined(js) and not defined(nimscript):
  block: # bug #18533
    proc c_getenv(env: cstring): cstring {.importc: "getenv", header: "<stdlib.h>".}
    var thr: Thread[void]
    proc threadFunc {.thread.} = putEnv("foo", "fooVal2")

    putEnv("foo", "fooVal1")
    doAssert getEnv("foo") == "fooVal1"
    createThread(thr, threadFunc)
    joinThreads(thr)
    doAssert getEnv("foo") == $c_getenv("foo")

    doAssertRaises(OSError): delEnv("foo=bar")
