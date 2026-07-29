#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

when defined(nimdoc):
  type
    Impl = distinct int64
    Time* = Impl ## \
      ## Wrapper for `time_t`. On posix, this is an alias to `posix.Time`.
elif defined(windows):
  # Unless _USE_32BIT_TIME_T is defined, time_t is a 64-bit value on both 32
  # and 64-bit versions of windows:
  # https://learn.microsoft.com/en-us/cpp/c-runtime-library/reference/time-time32-time64
  # For the avoidance of doubt, always use 64-bit version
  type Time* {.importc: "__time64_t", header: "<time.h>".} = distinct clonglong
elif defined(posix):
  import std/posix
  export posix.Time