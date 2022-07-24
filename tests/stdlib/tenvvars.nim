discard """
  matrix: "--threads:on"
  joinable: false
  targets: "c js cpp"
"""

import std/envvars
from std/sequtils import toSeq
import stdtest/testutils

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

main()

proc c_getenv(env: cstring): cstring {.importc: "getenv", header: "<stdlib.h>".}
proc c_wgetenv(env: WideCString): WideCString {.importc: "_wgetenv", header: "<stdlib.h>".}
proc c_wputenv(env: WideCString): int32 {.importc: "_wputenv", header: "<stdlib.h>".}

when not defined(js) and not defined(nimscript):
  block: # bug #18533
    var thr: Thread[void]
    proc threadFunc {.thread.} = putEnv("foo", "fooVal2")

    putEnv("foo", "fooVal1")
    doAssert getEnv("foo") == "fooVal1"
    createThread(thr, threadFunc)
    joinThreads(thr)
    doAssert getEnv("foo") == $c_wgetenv("foo".newWideCString)

    doAssertRaises(OSError): delEnv("foo=bar")

when defined(windows):
  const
    LC_ALL = 0
    unicodeAnsi = "\xc6" # `unicodeUtf8` in `windows-1252` encoding

  proc setlocale(category: cint, locale: cstring): cstring {.importc, header: "<locale.h>".}

  # Set locale required to represent `unicodeAnsi`
  discard setlocale(LC_ALL, cstring"English_United States.1252")

  block: # Feature #xxx
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
      doAssert $c_getenv(envName) == unicodeAnsi

    # Env. name containing Unicode characters is retrieved correctly
    block:
      const envName = unicodeUtf8 & "1"
      doAssert c_wputenv(newWideCString(envName & "=" & unicodeUtf8)) == 0
      doAssert existsEnv(envName)
      doAssert getEnv(envName) == unicodeUtf8

    # Env. name containing Unicode characters is set correctly
    block:
      const
        envName = unicodeUtf8 & "2"
        envNameAnsi = unicodeAnsi & "2"
      putEnv(envName, unicodeUtf8)
      doAssert existsEnv(envName)
      doAssert $c_wgetenv(envName.newWideCString) == unicodeUtf8
      doAssert $c_getenv(envNameAnsi.cstring) == unicodeAnsi

    # Env. name containing Unicode characters and empty value is set correctly
    block:
      const
        envName = unicodeUtf8 & "3"
        envNameAnsi = unicodeAnsi & "3"
      putEnv(envName, "")
      doAssert existsEnv(envName)
      doAssert $c_wgetenv(envName.newWideCString) == ""
      doAssert $c_getenv(envNameAnsi.cstring) == ""

    # Env. name containing Unicode characters and empty value is set correctly;
    # and, if env. name. characters cannot be represented in codepage, don't
    # raise an error.
    #
    # `win_setenv.nim` converts UTF-16 to ANSI when setting empty env. var. The
    # Polish_Poland.1250 locale has no representation of `unicodeUtf8`, so the
    # conversion will fail, but this must not be fatal. It is expected that the
    # routine ignores updating MBCS environment (`environ` global) and carries
    # on.
    block:
      const envName = unicodeUtf8 & "4"
      discard setlocale(LC_ALL, cstring"Polish_Poland.1250")
      putEnv(envName, "")
      doAssert existsEnv(envName)
      doAssert $c_wgetenv(envName.newWideCString) == ""
      doAssert getEnv(envName) == ""
