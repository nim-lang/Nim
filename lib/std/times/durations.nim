#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The `std/times/durations` module contains routines and types for dealing with durations of time.
## It is reexported by the `std/times <times.html>`_ modules
##
## A `Duration` represents a duration of time stored as seconds and
## nanoseconds. It is always fully normalized, so
## `initDuration(hours = 1)` and `initDuration(minutes = 60)` are equivalent.
##
## Arithmetic with a `Duration` is very fast, since it only involves basic arithmetic.

import core {.all.} # std/times/core

include "system/inclrtl"

type
  Duration* = object
    ## Represents a fixed duration of time, meaning a duration
    ## that has constant length independent of the context.
    ##
    ## To create a new `Duration`, use `initDuration
    ## <#initDuration,int64,int64,int64,int64,int64,int64,int64,int64>`_.
    ## Instead of trying to access the private attributes, use
    ## `inSeconds <#inSeconds,Duration>`_ for converting to seconds and
    ## `inNanoseconds <#inNanoseconds,Duration>`_ for converting to nanoseconds.
    seconds: int64
    nanosecond: NanosecondRange

  DurationParts* = array[FixedTimeUnit, int64] # Array of Duration parts starts

#
# Helper procs
#

{.pragma: operator, rtl, noSideEffect, benign.}

proc normalize(seconds, nanoseconds: int64): Duration =
  ## Normalize a (seconds, nanoseconds) pair and return it as
  ## a `Duration`. A normalized `Duration` has a
  ## positive nanosecond part in the range `NanosecondRange`.
  result.seconds = seconds + convert(Nanoseconds, Seconds, nanoseconds)
  var nanosecond = nanoseconds mod convert(Seconds, Nanoseconds, 1)
  if nanosecond < 0:
    nanosecond += convert(Seconds, Nanoseconds, 1)
    result.seconds -= 1
  result.nanosecond = nanosecond.int

#
# Duration
#

const DurationZero* = Duration() ## \
  ## Zero value for durations. Useful for comparisons.
  ##
  ## .. code-block:: nim
  ##
  ##   doAssert initDuration(seconds = 1) > DurationZero
  ##   doAssert initDuration(seconds = 0) == DurationZero

proc initDuration*(nanoseconds, microseconds, milliseconds,
                   seconds, minutes, hours, days, weeks: int64 = 0): Duration =
  ## Create a new `Duration <#Duration>`_.
  runnableExamples:
    let dur = initDuration(seconds = 1, milliseconds = 1)
    doAssert dur.inMilliseconds == 1001
    doAssert dur.inSeconds == 1

  let seconds = convert(Weeks, Seconds, weeks) +
    convert(Days, Seconds, days) +
    convert(Minutes, Seconds, minutes) +
    convert(Hours, Seconds, hours) +
    convert(Seconds, Seconds, seconds) +
    convert(Milliseconds, Seconds, milliseconds) +
    convert(Microseconds, Seconds, microseconds) +
    convert(Nanoseconds, Seconds, nanoseconds)
  let nanoseconds = (convert(Milliseconds, Nanoseconds, milliseconds mod 1000) +
    convert(Microseconds, Nanoseconds, microseconds mod 1_000_000) +
    nanoseconds mod 1_000_000_000).int
  # Nanoseconds might be negative so we must normalize.
  result = normalize(seconds, nanoseconds)

template convert(dur: Duration, unit: static[FixedTimeUnit]): int64 =
  # The correction is required due to how durations are normalized.
  # For example,` initDuration(nanoseconds = -1)` is stored as
  # { seconds = -1, nanoseconds = 999999999 }.
  when unit == Nanoseconds:
    dur.seconds * 1_000_000_000 + dur.nanosecond
  else:
    let correction = dur.seconds < 0 and dur.nanosecond > 0
    when unit >= Seconds:
      convert(Seconds, unit, dur.seconds + ord(correction))
    else:
      if correction:
        convert(Seconds, unit, dur.seconds + 1) -
          convert(Nanoseconds, unit,
            convert(Seconds, Nanoseconds, 1) - dur.nanosecond)
      else:
        convert(Seconds, unit, dur.seconds) +
          convert(Nanoseconds, unit, dur.nanosecond)

proc inWeeks*(dur: Duration): int64 =
  ## Converts the duration to the number of whole weeks.
  runnableExamples:
    let dur = initDuration(days = 8)
    doAssert dur.inWeeks == 1
  dur.convert(Weeks)

proc inDays*(dur: Duration): int64 =
  ## Converts the duration to the number of whole days.
  runnableExamples:
    let dur = initDuration(hours = -50)
    doAssert dur.inDays == -2
  dur.convert(Days)

proc inHours*(dur: Duration): int64 =
  ## Converts the duration to the number of whole hours.
  runnableExamples:
    let dur = initDuration(minutes = 60, days = 2)
    doAssert dur.inHours == 49
  dur.convert(Hours)

proc inMinutes*(dur: Duration): int64 =
  ## Converts the duration to the number of whole minutes.
  runnableExamples:
    let dur = initDuration(hours = 2, seconds = 10)
    doAssert dur.inMinutes == 120
  dur.convert(Minutes)

proc inSeconds*(dur: Duration): int64 =
  ## Converts the duration to the number of whole seconds.
  runnableExamples:
    let dur = initDuration(hours = 2, milliseconds = 10)
    doAssert dur.inSeconds == 2 * 60 * 60
  dur.convert(Seconds)

proc inMilliseconds*(dur: Duration): int64 =
  ## Converts the duration to the number of whole milliseconds.
  runnableExamples:
    let dur = initDuration(seconds = -2)
    doAssert dur.inMilliseconds == -2000
  dur.convert(Milliseconds)

proc inMicroseconds*(dur: Duration): int64 =
  ## Converts the duration to the number of whole microseconds.
  runnableExamples:
    let dur = initDuration(seconds = -2)
    doAssert dur.inMicroseconds == -2000000
  dur.convert(Microseconds)

proc inNanoseconds*(dur: Duration): int64 =
  ## Converts the duration to the number of whole nanoseconds.
  runnableExamples:
    let dur = initDuration(seconds = -2)
    doAssert dur.inNanoseconds == -2000000000
  dur.convert(Nanoseconds)

proc toParts*(dur: Duration): DurationParts =
  ## Converts a duration into an array consisting of fixed time units.
  ##
  ## Each value in the array gives information about a specific unit of
  ## time, for example `result[Days]` gives a count of days.
  ##
  ## This procedure is useful for converting `Duration` values to strings.
  runnableExamples:
    import std/times/core

    var dp = toParts(initDuration(weeks = 2, days = 1))
    doAssert dp[Days] == 1
    doAssert dp[Weeks] == 2
    doAssert dp[Minutes] == 0
    dp = toParts(initDuration(days = -1))
    doAssert dp[Days] == -1

  var remS = dur.seconds
  var remNs = dur.nanosecond.int

  # Ensure the same sign for seconds and nanoseconds
  if remS < 0 and remNs != 0:
    remNs -= convert(Seconds, Nanoseconds, 1)
    remS.inc 1

  for unit in countdown(Weeks, Seconds):
    let quantity = convert(Seconds, unit, remS)
    remS = remS mod convert(unit, Seconds, 1)

    result[unit] = quantity

  for unit in countdown(Milliseconds, Nanoseconds):
    let quantity = convert(Nanoseconds, unit, remNs)
    remNs = remNs mod convert(unit, Nanoseconds, 1)

    result[unit] = quantity

proc `$`*(dur: Duration): string =
  ## Human friendly string representation of a `Duration`.
  runnableExamples:
    doAssert $initDuration(seconds = 2) == "2 seconds"
    doAssert $initDuration(weeks = 1, days = 2) == "1 week and 2 days"
    doAssert $initDuration(hours = 1, minutes = 2, seconds = 3) ==
      "1 hour, 2 minutes, and 3 seconds"
    doAssert $initDuration(milliseconds = -1500) ==
      "-1 second and -500 milliseconds"
  var parts = newSeq[string]()
  var numParts = toParts(dur)

  for unit in countdown(Weeks, Nanoseconds):
    let quantity = numParts[unit]
    if quantity != 0.int64:
      parts.add(stringifyUnit(quantity, unit))

  result = humanizeParts(parts)

proc `+`*(a, b: Duration): Duration {.operator, extern: "ntAddDuration".} =
  ## Add two durations together.
  runnableExamples:
    doAssert initDuration(seconds = 1) + initDuration(days = 1) ==
      initDuration(seconds = 1, days = 1)
  normalize(a.seconds + b.seconds, a.nanosecond + b.nanosecond)

proc `-`*(a, b: Duration): Duration {.operator, extern: "ntSubDuration".} =
  ## Subtract a duration from another.
  runnableExamples:
    doAssert initDuration(seconds = 1, days = 1) - initDuration(seconds = 1) ==
      initDuration(days = 1)
  normalize(a.seconds - b.seconds, a.nanosecond - b.nanosecond)

proc `-`*(a: Duration): Duration {.operator, extern: "ntReverseDuration".} =
  ## Reverse a duration.
  runnableExamples:
    doAssert -initDuration(seconds = 1) == initDuration(seconds = -1)
  normalize(-a.seconds, -a.nanosecond)

proc `<`*(a, b: Duration): bool {.operator, extern: "ntLtDuration".} =
  ## Note that a duration can be negative,
  ## so even if `a < b` is true `a` might
  ## represent a larger absolute duration.
  ## Use `abs(a) < abs(b)` to compare the absolute
  ## duration.
  runnableExamples:
    doAssert initDuration(seconds = 1) < initDuration(seconds = 2)
    doAssert initDuration(seconds = -2) < initDuration(seconds = 1)
    doAssert initDuration(seconds = -2).abs < initDuration(seconds = 1).abs == false
  a.seconds < b.seconds or (
    a.seconds == b.seconds and a.nanosecond < b.nanosecond)

proc `<=`*(a, b: Duration): bool {.operator, extern: "ntLeDuration".} =
  a.seconds < b.seconds or (
    a.seconds == b.seconds and a.nanosecond <= b.nanosecond)

proc `==`*(a, b: Duration): bool {.operator, extern: "ntEqDuration".} =
  runnableExamples:
    let
      d1 = initDuration(weeks = 1)
      d2 = initDuration(days = 7)
    doAssert d1 == d2
  a.seconds == b.seconds and a.nanosecond == b.nanosecond

proc `*`*(a: int64, b: Duration): Duration {.operator,
    extern: "ntMulInt64Duration".} =
  ## Multiply a duration by some scalar.
  runnableExamples:
    doAssert 5 * initDuration(seconds = 1) == initDuration(seconds = 5)
    doAssert 3 * initDuration(minutes = 45) == initDuration(hours = 2, minutes = 15)
  normalize(a * b.seconds, a * b.nanosecond)

proc `*`*(a: Duration, b: int64): Duration {.operator,
    extern: "ntMulDuration".} =
  ## Multiply a duration by some scalar.
  runnableExamples:
    doAssert initDuration(seconds = 1) * 5 == initDuration(seconds = 5)
    doAssert initDuration(minutes = 45) * 3 == initDuration(hours = 2, minutes = 15)
  b * a

proc `+=`*(d1: var Duration, d2: Duration) =
  d1 = d1 + d2

proc `-=`*(dt: var Duration, ti: Duration) =
  dt = dt - ti

proc `*=`*(a: var Duration, b: int) =
  a = a * b

proc `div`*(a: Duration, b: int64): Duration {.operator, extern: "ntDivDuration".} =
  ## Integer division for durations.
  runnableExamples:
    doAssert initDuration(seconds = 3) div 2 ==
      initDuration(milliseconds = 1500)
    doAssert initDuration(minutes = 45) div 30 ==
      initDuration(minutes = 1, seconds = 30)
    doAssert initDuration(nanoseconds = 3) div 2 ==
      initDuration(nanoseconds = 1)
  let carryOver = convert(Seconds, Nanoseconds, a.seconds mod b)
  normalize(a.seconds div b, (a.nanosecond + carryOver) div b)

proc high*(typ: typedesc[Duration]): Duration =
  ## Get the longest representable duration.
  initDuration(seconds = high(int64), nanoseconds = high(NanosecondRange))

proc low*(typ: typedesc[Duration]): Duration =
  ## Get the longest representable duration of negative direction.
  initDuration(seconds = low(int64))

proc abs*(a: Duration): Duration =
  runnableExamples:
    doAssert initDuration(milliseconds = -1500).abs ==
      initDuration(milliseconds = 1500)
  initDuration(seconds = abs(a.seconds), nanoseconds = -a.nanosecond)
