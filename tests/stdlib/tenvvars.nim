discard """
  matrix: "--mm:refc; --mm:orc"
  joinable: false
  targets: "c js cpp"
"""

import std/envvars
from std/sequtils import toSeq
import stdtest/testutils
import std/[assertions]

when not defined(js):
  import std/typedthreads

# "LATIN CAPITAL LETTER AE" in UTF-8 (0xc386)
const unicodeUtf8 = "\xc3\x86"

template main =
  block: # delEnv, existsEnv, getEnv, envPairs
    for val in ["val", "", unicodeUtf8]: # ensures empty val works too
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

when defined(windows):
  import std/widestrs
  proc c_wgetenv(env: WideCString): WideCString {.importc: "_wgetenv", header: "<stdlib.h>".}
proc c_getenv(env: cstring): cstring {.importc: "getenv", header: "<stdlib.h>".}

when not defined(js) and not defined(nimscript):
  block: # bug #18533
    var thr: Thread[void]
    proc threadFunc {.thread.} = putEnv("foo", "fooVal2")

    putEnv("foo", "fooVal1")
    doAssert getEnv("foo") == "fooVal1"
    createThread(thr, threadFunc)
    joinThreads(thr)
    when defined(windows):
      doAssert getEnv("foo") == $c_wgetenv("foo".newWideCString)
    else:
      doAssert getEnv("foo") == $c_getenv("foo".cstring)

    doAssertRaises(OSError): delEnv("foo=bar")

when defined(windows) and not defined(nimscript):
  import std/encodings

  proc c_putenv(env: cstring): int32 {.importc: "putenv", header: "<stdlib.h>".}
  proc c_wputenv(env: WideCString): int32 {.importc: "_wputenv", header: "<stdlib.h>".}

  block: # Bug #20083
    # These test that `getEnv`, `putEnv` and `existsEnv` handle Unicode
    # characters correctly. This means that module X in the process calling the
    # CRT environment variable API will get the correct string. Raw CRT API
    # calls below represent module X.

    # Getting an env. var. with unicode characters returns the correct UTF-8
    # encoded string.
    block:
      const envName = "twin_envvars1"
      doAssert c_wputenv(newWideCString(envName & "=" & unicodeUtf8)) == 0
      doAssert existsEnv(envName)
      doAssert getEnv(envName) == unicodeUtf8

    # Putting an env. var. with unicode characters gives the correct UTF-16
    # encoded string from low-level routine.
    block:
      const envName = "twin_envvars2"
      putEnv(envName, unicodeUtf8)
      doAssert $c_wgetenv(envName.newWideCString) == unicodeUtf8

    # Env. name containing Unicode characters is retrieved correctly
    block:
      const envName = unicodeUtf8 & "1"
      doAssert c_wputenv(newWideCString(envName & "=" & unicodeUtf8)) == 0
      doAssert existsEnv(envName)
      doAssert getEnv(envName) == unicodeUtf8

    # Env. name containing Unicode characters is set correctly
    block:
      const envName = unicodeUtf8 & "2"
      putEnv(envName, unicodeUtf8)
      doAssert existsEnv(envName)
      doAssert $c_wgetenv(envName.newWideCString) == unicodeUtf8

    # Env. name containing Unicode characters and empty value is set correctly
    block:
      const envName = unicodeUtf8 & "3"
      putEnv(envName, "")
      doAssert existsEnv(envName)
      doAssert $c_wgetenv(envName.newWideCString) == ""

    # It's hard to test on Windows code pages, because there is no "change
    # a process' locale" API.
    if getCurrentEncoding(true) == "windows-1252":
      const
        unicodeAnsi = "\xc6" # `unicodeUtf8` in `windows-1252` encoding

      # Test that env. var. ANSI API has correct encoding
      block:
        const
          envName = unicodeUtf8 & "4"
          envNameAnsi = unicodeAnsi & "4"
        putEnv(envName, unicodeUtf8)
        doAssert $c_getenv(envNameAnsi.cstring) == unicodeAnsi

      block:
        const
          envName = unicodeUtf8 & "5"
          envNameAnsi = unicodeAnsi & "5"
        doAssert c_putenv((envNameAnsi & "=" & unicodeAnsi).cstring) == 0
        doAssert getEnv(envName) == unicodeUtf8

      # Env. name containing Unicode characters and empty value is set correctly;
      # and, if env. name. characters cannot be represented in codepage, don't
      # raise an error.
      #
      # `win_setenv.nim` converts UTF-16 to ANSI when setting empty env. var. The
      # windows-1250 locale has no representation of `abreveUtf8` below, so the
      # conversion will fail, but this must not be fatal. It is expected that the
      # routine ignores updating MBCS environment (`environ` global) and carries
      # on.
      block:
        const
          # "LATIN SMALL LETTER A WITH BREVE" in UTF-8
          abreveUtf8 = "\xc4\x83"
          envName = abreveUtf8 & "6"
        putEnv(envName, "")
        doAssert existsEnv(envName)
        doAssert $c_wgetenv(envName.newWideCString) == ""
        doAssert getEnv(envName) == ""
