#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time using a proleptic Gregorian calendar.
## It's is available for the `JavaScript target <backends.html#the-javascript-target>`_.
##
## The types uses nanosecond time resolution, but the underlying resolution used by ``getTime()``
## depends on the platform and backend (JS is limited to millisecond precision).
##
## Examples:
##
## .. code-block:: nim
##
##  import times, os
##  let time = cpuTime()
##
##  sleep(100)   # replace this with something to be timed
##  echo "Time taken: ",cpuTime() - time
##
##  echo "My formatted time: ", format(now(), "d MMMM yyyy HH:mm")
##  echo "Using predefined formats: ", getClockStr(), " ", getDateStr()
##
##  echo "cpuTime()  float value: ", cpuTime()
##  echo "An hour from now      : ", now() + 1.hours
##  echo "An hour from (UTC) now: ", getTime().utc + initDuration(hours = 1)

{.push debugger:off.} # the user does not want to trace a part
                      # of the standard library!

import
  strutils, parseutils, algorithm, math

include "system/inclrtl"

# This is really bad, but overflow checks are broken badly for
# ints on the JS backend. See #6752.
when defined(JS):
  {.push overflowChecks: off.}
  proc `*`(a, b: int64): int64 =
    system.`* `(a, b)
  proc `*`(a, b: int): int =
    system.`* `(a, b)
  proc `+`(a, b: int64): int64 =
    system.`+ `(a, b)
  proc `+`(a, b: int): int =
    system.`+ `(a, b)
  proc `-`(a, b: int64): int64 =
    system.`- `(a, b)
  proc `-`(a, b: int): int =
    system.`- `(a, b)
  proc inc(a: var int, b: int) =
    system.inc(a, b)
  proc inc(a: var int64, b: int) =
    system.inc(a, b)
  {.pop.}

when defined(posix):
  import posix

  type CTime = posix.Time

  var CLOCK_REALTIME {.importc: "CLOCK_REALTIME", header: "<time.h>".}: Clockid

  proc gettimeofday(tp: var Timeval, unused: pointer = nil) {.
    importc: "gettimeofday", header: "<sys/time.h>".}

  when not defined(freebsd) and not defined(netbsd) and not defined(openbsd):
    var timezone {.importc, header: "<time.h>".}: int
    tzset()

elif defined(windows):
  import winlean

  when defined(i386) and defined(gcc):
    type CTime {.importc: "time_t", header: "<time.h>".} = distinct int32
  else:
    # newest version of Visual C++ defines time_t to be of 64 bits
    type CTime {.importc: "time_t", header: "<time.h>".} = distinct int64
  # visual c's c runtime exposes these under a different name
  var timezone {.importc: "_timezone", header: "<time.h>".}: int

type
  Month* = enum ## Represents a month. Note that the enum starts at ``1``, so ``ord(month)`` will give
                ## the month number in the range ``[1..12]``.
    mJan = 1, mFeb, mMar, mApr, mMay, mJun, mJul, mAug, mSep, mOct, mNov, mDec

  WeekDay* = enum ## Represents a weekday.
    dMon, dTue, dWed, dThu, dFri, dSat, dSun

  MonthdayRange* = range[1..31]
  HourRange* = range[0..23]
  MinuteRange* = range[0..59]
  SecondRange* = range[0..60]
  YeardayRange* = range[0..365]
  NanosecondRange* = range[0..999_999_999]

  Time* = object ## Represents a point in time.
    seconds: int64
    nanosecond: NanosecondRange

  DateTime* = object of RootObj ## Represents a time in different parts.
                                ## Although this type can represent leap
                                ## seconds, they are generally not supported
                                ## in this module. They are not ignored,
                                ## but the ``DateTime``'s returned by
                                ## procedures in this module will never have
                                ## a leap second.
    nanosecond*: NanosecondRange ## The number of nanoseconds after the second,
                                 ## in the range 0 to 999_999_999.
    second*: SecondRange      ## The number of seconds after the minute,
                              ## normally in the range 0 to 59, but can
                              ## be up to 60 to allow for a leap second.
    minute*: MinuteRange      ## The number of minutes after the hour,
                              ## in the range 0 to 59.
    hour*: HourRange          ## The number of hours past midnight,
                              ## in the range 0 to 23.
    monthday*: MonthdayRange  ## The day of the month, in the range 1 to 31.
    month*: Month             ## The current month.
    year*: int                ## The current year, using astronomical year numbering
                              ## (meaning that before year 1 is year 0, then year -1 and so on).
    weekday*: WeekDay         ## The current day of the week.
    yearday*: YeardayRange    ## The number of days since January 1,
                              ## in the range 0 to 365.
    isDst*: bool              ## Determines whether DST is in effect.
                              ## Always false for the JavaScript backend.
    timezone*: Timezone       ## The timezone represented as an implementation of ``Timezone``.
    utcOffset*: int           ## The offset in seconds west of UTC, including any offset due to DST.
                              ## Note that the sign of this number is the opposite
                              ## of the one in a formatted offset string like ``+01:00``
                              ## (which would be parsed into the UTC offset ``-3600``).

  TimeInterval* = object ## Represents a non-fixed duration of time. Can be used to add and subtract
                         ## non-fixed time units from a ``DateTime`` or ``Time``.
                         ## ``TimeInterval`` doesn't represent a fixed duration of time,
                         ## since the duration of some units depend on the context (e.g a year
                         ## can be either 365 or 366 days long). The non-fixed time units are years,
                         ## months and days.

    nanoseconds*: int  ## The number of nanoseconds
    microseconds*: int ## The number of microseconds
    milliseconds*: int ## The number of milliseconds
    seconds*: int      ## The number of seconds
    minutes*: int      ## The number of minutes
    hours*: int        ## The number of hours
    days*: int         ## The number of days
    weeks*: int        ## The number of weeks
    months*: int       ## The number of months
    years*: int        ## The number of years

  Duration* = object ## Represents a fixed duration of time.
                     ## Uses the same time resolution as ``Time``.
                     ## This type should be prefered over ``TimeInterval`` unless
                     ## non-static time units is needed.
    seconds: int64
    nanosecond: NanosecondRange

  TimeUnit* = enum ## Different units of time.
    Nanoseconds, Microseconds, Milliseconds, Seconds, Minutes, Hours, Days, Weeks, Months, Years

  FixedTimeUnit* = range[Nanoseconds..Weeks] ## Subrange of ``TimeUnit`` that only includes units of fixed duration.
                                             ## These are the units that can be represented by a ``Duration``.

  Timezone* = object ## Timezone interface for supporting ``DateTime``'s of arbritary timezones.
                     ## The ``times`` module only supplies implementations for the systems local time and UTC.
                     ## The members ``zoneInfoFromUtc`` and ``zoneInfoFromTz`` should not be accessed directly
                     ## and are only exported so that ``Timezone`` can be implemented by other modules.
    zoneInfoFromUtc*: proc (time: Time): ZonedTime {.tags: [], raises: [], benign.}
    zoneInfoFromTz*:  proc (adjTime: Time): ZonedTime {.tags: [], raises: [], benign.}
    name*: string ## The name of the timezone, f.ex 'Europe/Stockholm' or 'Etc/UTC'. Used for checking equality.
                  ## Se also: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

  ZonedTime* = object ## Represents a zoned instant in time that is not associated with any calendar.
                      ## This type is only used for implementing timezones.
    adjTime*: Time  ## Time adjusted to a timezone.
    utcOffset*: int ## Offset from UTC in seconds.
                    ## The point in time represented by ``ZonedTime`` is ``adjTime + utcOffset.seconds``.
    isDst*: bool    ## Determines whether DST is in effect.

  DurationParts* = array[FixedTimeUnit, int64] # Array of Duration parts starts
  TimeIntervalParts* = array[TimeUnit, int] # Array of Duration parts starts
  TimesMutableTypes = DateTime | Time | Duration | TimeInterval

{.deprecated: [TMonth: Month, TWeekDay: WeekDay, TTime: Time,
    TTimeInterval: TimeInterval, TTimeInfo: DateTime, TimeInfo: DateTime].}

const
  secondsInMin = 60
  secondsInHour = 60*60
  secondsInDay = 60*60*24
  minutesInHour = 60
  rateDiff = 10000000'i64 # 100 nsecs
  # The number of hectonanoseconds between 1601/01/01 (windows epoch)
  # and 1970/01/01 (unix epoch).
  epochDiff = 116444736000000000'i64

const unitWeights: array[FixedTimeUnit, int64] = [
  1'i64,
  1000,
  1_000_000,
  1e9.int64,
  secondsInMin * 1e9.int64,
  secondsInHour * 1e9.int64,
  secondsInDay * 1e9.int64,
  7 * secondsInDay * 1e9.int64,
]

proc convert*[T: SomeInteger](unitFrom, unitTo: FixedTimeUnit, quantity: T): T {.inline.} =
  ## Convert a quantity of some duration unit to another duration unit.
  runnableExamples:
    doAssert convert(Days, Hours, 2) == 48
    doAssert convert(Days, Weeks, 13) == 1 # Truncated
    doAssert convert(Seconds, Milliseconds, -1) == -1000
  if unitFrom < unitTo:
    (quantity div (unitWeights[unitTo] div unitWeights[unitFrom])).T
  else:
    ((unitWeights[unitFrom] div unitWeights[unitTo]) * quantity).T

proc normalize[T: Duration|Time](seconds, nanoseconds: int64): T =
  ## Normalize a (seconds, nanoseconds) pair and return it as either
  ## a ``Duration`` or ``Time``. A normalized ``Duration|Time`` has a
  ## positive nanosecond part in the range ``NanosecondRange``.
  result.seconds = seconds + convert(Nanoseconds, Seconds, nanoseconds)
  var nanosecond = nanoseconds mod convert(Seconds, Nanoseconds, 1)
  if nanosecond < 0:
    nanosecond += convert(Seconds, Nanoseconds, 1)
    result.seconds -= 1
  result.nanosecond = nanosecond.int

# Forward declarations
proc utcZoneInfoFromUtc(time: Time): ZonedTime {.tags: [], raises: [], benign .}
proc utcZoneInfoFromTz(adjTime: Time): ZonedTime {.tags: [], raises: [], benign .}
proc localZoneInfoFromUtc(time: Time): ZonedTime {.tags: [], raises: [], benign .}
proc localZoneInfoFromTz(adjTime: Time): ZonedTime {.tags: [], raises: [], benign .}
proc initTime*(unix: int64, nanosecond: NanosecondRange): Time 
  {.tags: [], raises: [], benign noSideEffect.}

proc initDuration*(nanoseconds, microseconds, milliseconds,
                   seconds, minutes, hours, days, weeks: int64 = 0): Duration 
  {.tags: [], raises: [], benign noSideEffect.}

proc nanosecond*(time: Time): NanosecondRange =
  ## Get the fractional part of a ``Time`` as the number
  ## of nanoseconds of the second.
  time.nanosecond


proc weeks*(dur: Duration): int64 {.inline.} =
  ## Number of whole weeks represented by the duration.
  convert(Seconds, Weeks, dur.seconds)

proc days*(dur: Duration): int64 {.inline.} =
  ## Number of whole days represented by the duration.
  convert(Seconds, Days, dur.seconds)

proc minutes*(dur: Duration): int64 {.inline.} =
  ## Number of whole minutes represented by the duration.
  convert(Seconds, Minutes, dur.seconds)

proc hours*(dur: Duration): int64 {.inline.} =
  ## Number of whole hours represented by the duration.
  convert(Seconds, Hours, dur.seconds)

proc seconds*(dur: Duration): int64 {.inline.} =
  ## Number of whole seconds represented by the duration.
  dur.seconds

proc milliseconds*(dur: Duration): int {.inline.} =
  ## Number of whole milliseconds represented by the **fractional**
  ## part of the duration.
  runnableExamples:
    let dur = initDuration(seconds = 1, milliseconds = 1)
    doAssert dur.milliseconds == 1
  convert(Nanoseconds, Milliseconds, dur.nanosecond)

proc microseconds*(dur: Duration): int {.inline.} =
  ## Number of whole microseconds represented by the **fractional**
  ## part of the duration.
  runnableExamples:
    let dur = initDuration(seconds = 1, microseconds = 1)
    doAssert dur.microseconds == 1
  convert(Nanoseconds, Microseconds, dur.nanosecond)

proc nanoseconds*(dur: Duration): int {.inline.} =
  ## Number of whole nanoseconds represented by the **fractional**
  ## part of the duration.
  runnableExamples:
    let dur = initDuration(seconds = 1, nanoseconds = 1)
    doAssert dur.nanoseconds == 1
  dur.nanosecond

proc fractional*(dur: Duration): Duration {.inline.} =
  ## The fractional part of duration, as a duration.
  runnableExamples:
    let dur = initDuration(seconds = 1, nanoseconds = 5)
    doAssert dur.fractional == initDuration(nanoseconds = 5)
  initDuration(nanoseconds = dur.nanosecond)


proc fromUnix*(unix: int64): Time {.benign, tags: [], raises: [], noSideEffect.} =
  ## Convert a unix timestamp (seconds since ``1970-01-01T00:00:00Z``) to a ``Time``.
  runnableExamples:
    doAssert $fromUnix(0).utc == "1970-01-01T00:00:00+00:00"
  initTime(unix, 0)

proc toUnix*(t: Time): int64 {.benign, tags: [], raises: [], noSideEffect.} =
  ## Convert ``t`` to a unix timestamp (seconds since ``1970-01-01T00:00:00Z``).
  runnableExamples:
    doAssert fromUnix(0).toUnix() == 0

  t.seconds

proc fromWinTime*(win: int64): Time =
  ## Convert a Windows file time (100-nanosecond intervals since ``1601-01-01T00:00:00Z``)
  ## to a ``Time``.
  let hnsecsSinceEpoch = (win - epochDiff)
  var seconds = hnsecsSinceEpoch div rateDiff
  var nanos = ((hnsecsSinceEpoch mod rateDiff) * 100).int
  if nanos < 0:
    nanos += convert(Seconds, Nanoseconds, 1)
    seconds -= 1
  result = initTime(seconds, nanos)

proc toWinTime*(t: Time): int64 =
  ## Convert ``t`` to a Windows file time (100-nanosecond intervals since ``1601-01-01T00:00:00Z``).
  result = t.seconds * rateDiff + epochDiff + t.nanosecond div 100

proc isLeapYear*(year: int): bool =
  ## Returns true if ``year`` is a leap year.
  year mod 4 == 0 and (year mod 100 != 0 or year mod 400 == 0)

proc getDaysInMonth*(month: Month, year: int): int =
  ## Get the number of days in a ``month`` of a ``year``.
  # http://www.dispersiondesign.com/articles/time/number_of_days_in_a_month
  case month
  of mFeb: result = if isLeapYear(year): 29 else: 28
  of mApr, mJun, mSep, mNov: result = 30
  else: result = 31

proc getDaysInYear*(year: int): int =
  ## Get the number of days in a ``year``
  result = 365 + (if isLeapYear(year): 1 else: 0)

proc assertValidDate(monthday: MonthdayRange, month: Month, year: int) {.inline.} =
  assert monthday <= getDaysInMonth(month, year),
    $year & "-" & intToStr(ord(month), 2) & "-" & $monthday & " is not a valid date"

proc toEpochDay(monthday: MonthdayRange, month: Month, year: int): int64 =
  ## Get the epoch day from a year/month/day date.
  ## The epoch day is the number of days since 1970/01/01 (it might be negative).
  assertValidDate monthday, month, year
  # Based on http://howardhinnant.github.io/date_algorithms.html
  var (y, m, d) = (year, ord(month), monthday.int)
  if m <= 2:
    y.dec

  let era = (if y >= 0: y else: y-399) div 400
  let yoe = y - era * 400
  let doy = (153 * (m + (if m > 2: -3 else: 9)) + 2) div 5 + d-1
  let doe = yoe * 365 + yoe div 4 - yoe div 100 + doy
  return era * 146097 + doe - 719468

proc fromEpochDay(epochday: int64): tuple[monthday: MonthdayRange, month: Month, year: int] =
  ## Get the year/month/day date from a epoch day.
  ## The epoch day is the number of days since 1970/01/01 (it might be negative).
  # Based on http://howardhinnant.github.io/date_algorithms.html
  var z = epochday
  z.inc 719468
  let era = (if z >= 0: z else: z - 146096) div 146097
  let doe = z - era * 146097
  let yoe = (doe - doe div 1460 + doe div 36524 - doe div 146096) div 365
  let y = yoe + era * 400;
  let doy = doe - (365 * yoe + yoe div 4 - yoe div 100)
  let mp = (5 * doy + 2) div 153
  let d = doy - (153 * mp + 2) div 5 + 1
  let m = mp + (if mp < 10: 3 else: -9)
  return (d.MonthdayRange, m.Month, (y + ord(m <= 2)).int)

proc getDayOfYear*(monthday: MonthdayRange, month: Month, year: int): YeardayRange {.tags: [], raises: [], benign .} =
  ## Returns the day of the year.
  ## Equivalent with ``initDateTime(day, month, year).yearday``.
  assertValidDate monthday, month, year
  const daysUntilMonth:     array[Month, int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  const daysUntilMonthLeap: array[Month, int] = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

  if isLeapYear(year):
    result = daysUntilMonthLeap[month] + monthday - 1
  else:
    result = daysUntilMonth[month] + monthday - 1

proc getDayOfWeek*(monthday: MonthdayRange, month: Month, year: int): WeekDay {.tags: [], raises: [], benign .} =
  ## Returns the day of the week enum from day, month and year.
  ## Equivalent with ``initDateTime(day, month, year).weekday``.
  assertValidDate monthday, month, year
  # 1970-01-01 is a Thursday, we adjust to the previous Monday
  let days = toEpochday(monthday, month, year) - 3
  let weeks = (if days >= 0: days else: days - 6) div 7
  let wd = days - weeks * 7
  # The value of d is 0 for a Sunday, 1 for a Monday, 2 for a Tuesday, etc.
  # so we must correct for the WeekDay type.
  result = if wd == 0: dSun else: WeekDay(wd - 1)


{. pragma: operator, rtl, noSideEffect, benign .}

template subImpl[T: Duration|Time](a: Duration|Time, b: Duration|Time): T =
  normalize[T](a.seconds - b.seconds, a.nanosecond - b.nanosecond)

template addImpl[T: Duration|Time](a: Duration|Time, b: Duration|Time): T =
  normalize[T](a.seconds + b.seconds, a.nanosecond + b.nanosecond)

template ltImpl(a: Duration|Time, b: Duration|Time): bool =
  a.seconds < b.seconds or (
    a.seconds == b.seconds and a.nanosecond < b.nanosecond)

template lqImpl(a: Duration|Time, b: Duration|Time): bool =
  a.seconds < b.seconds or (
    a.seconds == b.seconds and a.nanosecond <= b.nanosecond)

template eqImpl(a: Duration|Time, b: Duration|Time): bool =
  a.seconds == b.seconds and a.nanosecond == b.nanosecond

proc initDuration*(nanoseconds, microseconds, milliseconds,
                   seconds, minutes, hours, days, weeks: int64 = 0): Duration =
  runnableExamples:
    let dur = initDuration(seconds = 1, milliseconds = 1)
    doAssert dur.milliseconds == 1
    doAssert dur.seconds == 1

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
  result = normalize[Duration](seconds, nanoseconds)

const DurationZero* = initDuration() ## \
  ## Zero value for durations. Useful for comparisons.
  ##
  ## .. code-block:: nim
  ##
  ##   doAssert initDuration(seconds = 1) > DurationZero
  ##   doAssert initDuration(seconds = 0) == DurationZero

proc toParts*(dur: Duration): DurationParts =
  ## Converts a duration into an array consisting of fixed time units.
  ##
  ## Each value in the array gives information about a specific unit of
  ## time, for example ``result[Days]`` gives a count of days.
  ##
  ## This procedure is useful for converting ``Duration`` values to strings.
  runnableExamples:
    var dp = toParts(initDuration(weeks=2, days=1))
    doAssert dp[Days] == 1
    doAssert dp[Weeks] == 2
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

proc stringifyUnit*(value: int | int64, unit: string): string =
  ## Stringify time unit with it's name, lowercased
  runnableExamples:
    doAssert stringifyUnit(2, "Seconds") == "2 seconds"
    doAssert stringifyUnit(1, "Years") == "1 year"
  result = ""
  result.add($value)
  result.add(" ")
  if abs(value) != 1:
    result.add(unit.toLowerAscii())
  else:
    result.add(unit[0..^2].toLowerAscii())

proc humanizeParts(parts: seq[string]): string =
  ## Make date string parts human-readable

  result = ""
  if parts.len == 0:
    result.add "0 nanoseconds"
  elif parts.len == 1:
    result = parts[0]
  elif parts.len == 2:
    result = parts[0] & " and " & parts[1]
  else:
    for part in parts[0..high(parts)-1]:
      result.add part & ", "
    result.add "and " & parts[high(parts)]

proc `$`*(dur: Duration): string =
  ## Human friendly string representation of ``Duration``.
  runnableExamples:
    doAssert $initDuration(seconds = 2) == "2 seconds"
    doAssert $initDuration(weeks = 1, days = 2) == "1 week and 2 days"
    doAssert $initDuration(hours = 1, minutes = 2, seconds = 3) == "1 hour, 2 minutes, and 3 seconds"
    doAssert $initDuration(milliseconds = -1500) == "-1 second and -500 milliseconds"
  var parts = newSeq[string]()
  var numParts = toParts(dur)

  for unit in countdown(Weeks, Nanoseconds):
    let quantity = numParts[unit]
    if quantity != 0.int64:
      parts.add(stringifyUnit(quantity, $unit))
  
  result = humanizeParts(parts)

proc `+`*(a, b: Duration): Duration {.operator.} =
  ## Add two durations together.
  runnableExamples:
    doAssert initDuration(seconds = 1) + initDuration(days = 1) ==
      initDuration(seconds = 1, days = 1)
  addImpl[Duration](a, b)

proc `-`*(a, b: Duration): Duration {.operator.} =
  ## Subtract a duration from another.
  runnableExamples:
    doAssert initDuration(seconds = 1, days = 1) - initDuration(seconds = 1) ==
      initDuration(days = 1)
  subImpl[Duration](a, b)

proc `-`*(a: Duration): Duration {.operator.} =
  ## Reverse a duration.
  runnableExamples:
    doAssert -initDuration(seconds = 1) == initDuration(seconds = -1)
  normalize[Duration](-a.seconds, -a.nanosecond)

proc `<`*(a, b: Duration): bool {.operator.} =
  ## Note that a duration can be negative,
  ## so even if ``a < b`` is true ``a`` might
  ## represent a larger absolute duration.
  ## Use ``abs(a) < abs(b)`` to compare the absolute
  ## duration.
  runnableExamples:
    doAssert initDuration(seconds =  1) < initDuration(seconds = 2)
    doAssert initDuration(seconds = -2) < initDuration(seconds = 1)
  ltImpl(a, b)

proc `<=`*(a, b: Duration): bool {.operator.} =
  lqImpl(a, b)

proc `==`*(a, b: Duration): bool {.operator.} =
  eqImpl(a, b)

proc `*`*(a: int64, b: Duration): Duration {.operator} =
  ## Multiply a duration by some scalar.
  runnableExamples:
    doAssert 5 * initDuration(seconds = 1) == initDuration(seconds = 5)
  normalize[Duration](a * b.seconds, a * b.nanosecond)

proc `*`*(a: Duration, b: int64): Duration {.operator} =
  ## Multiply a duration by some scalar.
  runnableExamples:
    doAssert initDuration(seconds = 1) * 5 == initDuration(seconds = 5)
  b * a

proc `div`*(a: Duration, b: int64): Duration {.operator} =
  ## Integer division for durations.
  runnableExamples:
    doAssert initDuration(seconds = 3) div 2 == initDuration(milliseconds = 1500)
    doAssert initDuration(nanoseconds = 3) div 2 == initDuration(nanoseconds = 1)
  let carryOver = convert(Seconds, Nanoseconds, a.seconds mod b)
  normalize[Duration](a.seconds div b, (a.nanosecond + carryOver) div b)

proc initTime*(unix: int64, nanosecond: NanosecondRange): Time =
  ## Create a ``Time`` from a unix timestamp and a nanosecond part.
  result.seconds = unix
  result.nanosecond = nanosecond

proc `-`*(a, b: Time): Duration {.operator, extern: "ntDiffTime".} =
  ## Computes the duration between two points in time.
  subImpl[Duration](a, b)

proc `+`*(a: Time, b: Duration): Time {.operator, extern: "ntAddTime".} =
  ## Add a duration of time to a ``Time``.
  runnableExamples:
    doAssert (fromUnix(0) + initDuration(seconds = 1)) == fromUnix(1)
  addImpl[Time](a, b)

proc `-`*(a: Time, b: Duration): Time {.operator, extern: "ntSubTime".} =
  ## Subtracts a duration of time from a ``Time``.
  runnableExamples:
    doAssert (fromUnix(0) - initDuration(seconds = 1)) == fromUnix(-1)
  subImpl[Time](a, b)

proc `<`*(a, b: Time): bool {.operator, extern: "ntLtTime".} =
  ## Returns true iff ``a < b``, that is iff a happened before b.
  ltImpl(a, b)

proc `<=` * (a, b: Time): bool {.operator, extern: "ntLeTime".} =
  ## Returns true iff ``a <= b``.
  lqImpl(a, b)

proc `==`*(a, b: Time): bool {.operator, extern: "ntEqTime".} =
  ## Returns true if ``a == b``, that is if both times represent the same point in time.
  eqImpl(a, b)

proc high*(typ: typedesc[Time]): Time =
  initTime(high(int64), high(NanosecondRange))

proc low*(typ: typedesc[Time]): Time =
  initTime(low(int64), 0)

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

proc toTime*(dt: DateTime): Time {.tags: [], raises: [], benign.} =
  ## Converts a broken-down time structure to
  ## calendar time representation.
  let epochDay = toEpochday(dt.monthday, dt.month, dt.year)
  var seconds = epochDay * secondsInDay
  seconds.inc dt.hour * secondsInHour
  seconds.inc dt.minute * 60
  seconds.inc dt.second
  # The code above ignores the UTC offset of `timeInfo`,
  # so we need to compensate for that here.
  seconds.inc dt.utcOffset
  result = initTime(seconds, dt.nanosecond)

proc initDateTime(zt: ZonedTime, zone: Timezone): DateTime =
  ## Create a new ``DateTime`` using ``ZonedTime`` in the specified timezone.
  let s = zt.adjTime.seconds
  let epochday = (if s >= 0: s else: s - (secondsInDay - 1)) div secondsInDay
  var rem = s - epochday * secondsInDay
  let hour = rem div secondsInHour
  rem = rem - hour * secondsInHour
  let minute = rem div secondsInMin
  rem = rem - minute * secondsInMin
  let second = rem

  let (d, m, y) = fromEpochday(epochday)

  DateTime(
    year: y,
    month: m,
    monthday: d,
    hour: hour,
    minute: minute,
    second: second,
    nanosecond: zt.adjTime.nanosecond,
    weekday: getDayOfWeek(d, m, y),
    yearday: getDayOfYear(d, m, y),
    isDst: zt.isDst,
    timezone: zone,
    utcOffset: zt.utcOffset
  )

proc inZone*(time: Time, zone: Timezone): DateTime {.tags: [], raises: [], benign.} =
  ## Break down ``time`` into a ``DateTime`` using ``zone`` as the timezone.
  let zoneInfo = zone.zoneInfoFromUtc(time)
  result = initDateTime(zoneInfo, zone)

proc inZone*(dt: DateTime, zone: Timezone): DateTime  {.tags: [], raises: [], benign.} =
  ## Convert ``dt`` into a ``DateTime`` using ``zone`` as the timezone.
  dt.toTime.inZone(zone)

proc `$`*(zone: Timezone): string =
  ## Returns the name of the timezone.
  zone.name

proc `==`*(zone1, zone2: Timezone): bool =
  ## Two ``Timezone``'s are considered equal if their name is equal.
  zone1.name == zone2.name

proc toAdjTime(dt: DateTime): Time =
  let epochDay = toEpochday(dt.monthday, dt.month, dt.year)
  var seconds = epochDay * secondsInDay
  seconds.inc dt.hour * secondsInHour
  seconds.inc dt.minute * secondsInMin
  seconds.inc dt.second
  result = initTime(seconds, dt.nanosecond)

when defined(JS):
    type JsDate = object
    proc newDate(year, month, date, hours, minutes, seconds, milliseconds: int): JsDate {.tags: [], raises: [], importc: "new Date".}
    proc newDate(): JsDate {.importc: "new Date".}
    proc newDate(value: float): JsDate {.importc: "new Date".}
    proc getTimezoneOffset(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getDay(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getFullYear(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getHours(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getMilliseconds(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getMinutes(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getMonth(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getSeconds(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getTime(js: JsDate): int {.tags: [], raises: [], noSideEffect, benign, importcpp.}
    proc getDate(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCDate(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCFullYear(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCHours(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCMilliseconds(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCMinutes(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCMonth(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCSeconds(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getUTCDay(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc getYear(js: JsDate): int {.tags: [], raises: [], benign, importcpp.}
    proc setFullYear(js: JsDate, year: int): void {.tags: [], raises: [], benign, importcpp.}

    proc localZoneInfoFromUtc(time: Time): ZonedTime =
      let jsDate = newDate(time.seconds.float * 1000)
      let offset = jsDate.getTimezoneOffset() * secondsInMin
      result.adjTime = time - initDuration(seconds = offset)
      result.utcOffset = offset
      result.isDst = false

    proc localZoneInfoFromTz(adjTime: Time): ZonedTime =
      let utcDate = newDate(adjTime.seconds.float * 1000)
      let localDate = newDate(utcDate.getUTCFullYear(), utcDate.getUTCMonth(), utcDate.getUTCDate(),
        utcDate.getUTCHours(), utcDate.getUTCMinutes(), utcDate.getUTCSeconds(), 0)

      # This is as dumb as it looks - JS doesn't support years in the range 0-99 in the constructor
      # because they are assumed to be 19xx...
      # Because JS doesn't support timezone history, it doesn't really matter in practice.
      if utcDate.getUTCFullYear() in 0 .. 99:
        localDate.setFullYear(utcDate.getUTCFullYear())

      result.adjTime = adjTime
      result.utcOffset = localDate.getTimezoneOffset() * secondsInMin
      result.isDst = false

else:
  when defined(freebsd) or defined(netbsd) or defined(openbsd) or
      defined(macosx):
    type
      StructTm {.importc: "struct tm".} = object
        second {.importc: "tm_sec".},
          minute {.importc: "tm_min".},
          hour {.importc: "tm_hour".},
          monthday {.importc: "tm_mday".},
          month {.importc: "tm_mon".},
          year {.importc: "tm_year".},
          weekday {.importc: "tm_wday".},
          yearday {.importc: "tm_yday".},
          isdst {.importc: "tm_isdst".}: cint
        gmtoff {.importc: "tm_gmtoff".}: clong
  else:
    type
      StructTm {.importc: "struct tm".} = object
        second {.importc: "tm_sec".},
          minute {.importc: "tm_min".},
          hour {.importc: "tm_hour".},
          monthday {.importc: "tm_mday".},
          month {.importc: "tm_mon".},
          year {.importc: "tm_year".},
          weekday {.importc: "tm_wday".},
          yearday {.importc: "tm_yday".},
          isdst {.importc: "tm_isdst".}: cint
        when defined(linux) and defined(amd64):
          gmtoff {.importc: "tm_gmtoff".}: clong
          zone {.importc: "tm_zone".}: cstring
  type
    StructTmPtr = ptr StructTm

  proc localtime(timer: ptr CTime): StructTmPtr {. importc: "localtime", header: "<time.h>", tags: [].}

  proc toAdjUnix(tm: StructTm): int64 =
    let epochDay = toEpochday(tm.monthday, (tm.month + 1).Month, tm.year.int + 1900)
    result = epochDay * secondsInDay
    result.inc tm.hour * secondsInHour
    result.inc tm.minute * 60
    result.inc tm.second

  proc getLocalOffsetAndDst(unix: int64): tuple[offset: int, dst: bool] =
    var a = unix.CTime
    let tmPtr = localtime(addr(a))
    if not tmPtr.isNil:
      let tm = tmPtr[]
      return ((unix - tm.toAdjUnix).int, tm.isdst > 0)
    return (0, false)

  proc localZoneInfoFromUtc(time: Time): ZonedTime =
    let (offset, dst) = getLocalOffsetAndDst(time.seconds)
    result.adjTime = time - initDuration(seconds = offset)
    result.utcOffset = offset
    result.isDst = dst

  proc localZoneInfoFromTz(adjTime: Time): ZonedTime  =
    var adjUnix = adjTime.seconds
    let past = adjUnix - secondsInDay
    let (pastOffset, _) = getLocalOffsetAndDst(past)

    let future = adjUnix + secondsInDay
    let (futureOffset, _) = getLocalOffsetAndDst(future)

    var utcOffset: int
    if pastOffset == futureOffset:
        utcOffset = pastOffset.int
    else:
      if pastOffset > futureOffset:
        adjUnix -= secondsInHour

      adjUnix += pastOffset
      utcOffset = getLocalOffsetAndDst(adjUnix).offset

    # This extra roundtrip is needed to normalize any impossible datetimes
    # as a result of offset changes (normally due to dst)
    let utcUnix = adjTime.seconds + utcOffset
    let (finalOffset, dst) = getLocalOffsetAndDst(utcUnix)
    result.adjTime = initTime(utcUnix - finalOffset, adjTime.nanosecond)
    result.utcOffset = finalOffset
    result.isDst = dst

proc utcZoneInfoFromUtc(time: Time): ZonedTime =
  result.adjTime = time
  result.utcOffset = 0
  result.isDst = false

proc utcZoneInfoFromTz(adjTime: Time): ZonedTime =
  utcZoneInfoFromUtc(adjTime) # adjTime == time since we are in UTC

proc utc*(): TimeZone =
  ## Get the ``Timezone`` implementation for the UTC timezone.
  runnableExamples:
    doAssert now().utc.timezone == utc()
    doAssert utc().name == "Etc/UTC"
  Timezone(zoneInfoFromUtc: utcZoneInfoFromUtc, zoneInfoFromTz: utcZoneInfoFromTz, name: "Etc/UTC")

proc local*(): TimeZone =
  ## Get the ``Timezone`` implementation for the local timezone.
  runnableExamples:
   doAssert now().timezone == local()
   doAssert local().name == "LOCAL"
  Timezone(zoneInfoFromUtc: localZoneInfoFromUtc, zoneInfoFromTz: localZoneInfoFromTz, name: "LOCAL")

proc utc*(dt: DateTime): DateTime =
  ## Shorthand for ``dt.inZone(utc())``.
  dt.inZone(utc())

proc local*(dt: DateTime): DateTime =
  ## Shorthand for ``dt.inZone(local())``.
  dt.inZone(local())

proc utc*(t: Time): DateTime =
  ## Shorthand for ``t.inZone(utc())``.
  t.inZone(utc())

proc local*(t: Time): DateTime =
  ## Shorthand for ``t.inZone(local())``.
  t.inZone(local())

proc getTime*(): Time {.tags: [TimeEffect], benign.} =
  ## Gets the current time as a ``Time`` with nanosecond resolution.
  when defined(JS):
    let millis = newDate().getTime()
    let seconds = convert(Milliseconds, Seconds, millis)
    let nanos = convert(Milliseconds, Nanoseconds,
      millis mod convert(Seconds, Milliseconds, 1).int)
    result = initTime(seconds, nanos)
  # I'm not entirely certain if freebsd needs to use `gettimeofday`.
  elif defined(macosx) or defined(freebsd):
    var a: Timeval
    gettimeofday(a)
    result = initTime(a.tv_sec.int64, convert(Microseconds, Nanoseconds, a.tv_usec.int))
  elif defined(posix):
    var ts: Timespec
    discard clock_gettime(CLOCK_REALTIME, ts)
    result = initTime(ts.tv_sec.int64, ts.tv_nsec.int)
  elif defined(windows):
    var f: FILETIME
    getSystemTimeAsFileTime(f)
    result = fromWinTime(rdFileTime(f))

proc now*(): DateTime {.tags: [TimeEffect], benign.} =
  ## Get the current time as a  ``DateTime`` in the local timezone.
  ##
  ## Shorthand for ``getTime().local``.
  getTime().local

proc initTimeInterval*(nanoseconds, microseconds, milliseconds,
                       seconds, minutes, hours,
                       days, weeks, months, years: int = 0): TimeInterval =
  ## Creates a new ``TimeInterval``.
  ##
  ## You can also use the convenience procedures called ``milliseconds``,
  ## ``seconds``, ``minutes``, ``hours``, ``days``, ``months``, and ``years``.
  ##
  runnableExamples:
    let day = initTimeInterval(hours=24)
    let dt = initDateTime(01, mJan, 2000, 12, 00, 00, utc())
    doAssert $(dt + day) == "2000-01-02T12:00:00+00:00"
  result.nanoseconds = nanoseconds
  result.microseconds = microseconds
  result.milliseconds = milliseconds
  result.seconds = seconds
  result.minutes = minutes
  result.hours = hours
  result.days = days
  result.weeks = weeks
  result.months = months
  result.years = years

proc `+`*(ti1, ti2: TimeInterval): TimeInterval =
  ## Adds two ``TimeInterval`` objects together.
  result.nanoseconds = ti1.nanoseconds + ti2.nanoseconds
  result.microseconds = ti1.microseconds + ti2.microseconds
  result.milliseconds = ti1.milliseconds + ti2.milliseconds
  result.seconds = ti1.seconds + ti2.seconds
  result.minutes = ti1.minutes + ti2.minutes
  result.hours = ti1.hours + ti2.hours
  result.days = ti1.days + ti2.days
  result.weeks = ti1.weeks + ti2.weeks
  result.months = ti1.months + ti2.months
  result.years = ti1.years + ti2.years

proc `-`*(ti: TimeInterval): TimeInterval =
  ## Reverses a time interval
  runnableExamples:
    let day = -initTimeInterval(hours=24)
    doAssert day.hours == -24

  result = TimeInterval(
    nanoseconds: -ti.nanoseconds,
    microseconds: -ti.microseconds,
    milliseconds: -ti.milliseconds,
    seconds: -ti.seconds,
    minutes: -ti.minutes,
    hours: -ti.hours,
    days: -ti.days,
    weeks: -ti.weeks,
    months: -ti.months,
    years: -ti.years
  )

proc `-`*(ti1, ti2: TimeInterval): TimeInterval =
  ## Subtracts TimeInterval ``ti1`` from ``ti2``.
  ##
  ## Time components are subtracted one-by-one, see output:
  runnableExamples:
    let ti1 = initTimeInterval(hours=24)
    let ti2 = initTimeInterval(hours=4)
    doAssert (ti1 - ti2) == initTimeInterval(hours=20)

  result = ti1 + (-ti2)

proc getDateStr*(): string {.rtl, extern: "nt$1", tags: [TimeEffect].} =
  ## Gets the current date as a string of the format ``YYYY-MM-DD``.
  var ti = now()
  result = $ti.year & '-' & intToStr(ord(ti.month), 2) &
    '-' & intToStr(ti.monthday, 2)

proc getClockStr*(): string {.rtl, extern: "nt$1", tags: [TimeEffect].} =
  ## Gets the current clock time as a string of the format ``HH:MM:SS``.
  var ti = now()
  result = intToStr(ti.hour, 2) & ':' & intToStr(ti.minute, 2) &
    ':' & intToStr(ti.second, 2)

proc `$`*(day: WeekDay): string =
  ## Stringify operator for ``WeekDay``.
  const lookup: array[WeekDay, string] = ["Monday", "Tuesday", "Wednesday",
     "Thursday", "Friday", "Saturday", "Sunday"]
  return lookup[day]

proc `$`*(m: Month): string =
  ## Stringify operator for ``Month``.
  const lookup: array[Month, string] = ["January", "February", "March",
      "April", "May", "June", "July", "August", "September", "October",
      "November", "December"]
  return lookup[m]


proc toParts* (ti: TimeInterval): TimeIntervalParts =
  ## Converts a `TimeInterval` into an array consisting of its time units,
  ## starting with nanoseconds and ending with years
  ##
  ## This procedure is useful for converting ``TimeInterval`` values to strings.
  ## E.g. then you need to implement custom interval printing
  runnableExamples:
    var tp = toParts(initTimeInterval(years=1, nanoseconds=123))
    doAssert tp[Years] == 1
    doAssert tp[Nanoseconds] == 123

  var index = 0
  for name, value in fieldPairs(ti):
    result[index.TimeUnit()] = value
    index += 1

proc `$`*(ti: TimeInterval): string =
  ## Get string representation of `TimeInterval`
  runnableExamples:
    doAssert $initTimeInterval(years=1, nanoseconds=123) == "1 year and 123 nanoseconds"
    doAssert $initTimeInterval() == "0 nanoseconds"

  var parts: seq[string] = @[]
  var tiParts = toParts(ti)
  for unit in countdown(Years, Nanoseconds):
    if tiParts[unit] != 0:
      parts.add(stringifyUnit(tiParts[unit], $unit))

  result = humanizeParts(parts)

proc nanoseconds*(nanos: int): TimeInterval {.inline.} =
  ## TimeInterval of ``nanos`` nanoseconds.
  initTimeInterval(nanoseconds = nanos)

proc microseconds*(micros: int): TimeInterval {.inline.} =
  ## TimeInterval of ``micros`` microseconds.
  initTimeInterval(microseconds = micros)

proc milliseconds*(ms: int): TimeInterval {.inline.} =
  ## TimeInterval of ``ms`` milliseconds.
  initTimeInterval(milliseconds = ms)

proc seconds*(s: int): TimeInterval {.inline.} =
  ## TimeInterval of ``s`` seconds.
  ##
  ## ``echo getTime() + 5.second``
  initTimeInterval(seconds = s)

proc minutes*(m: int): TimeInterval {.inline.} =
  ## TimeInterval of ``m`` minutes.
  ##
  ## ``echo getTime() + 5.minutes``
  initTimeInterval(minutes = m)

proc hours*(h: int): TimeInterval {.inline.} =
  ## TimeInterval of ``h`` hours.
  ##
  ## ``echo getTime() + 2.hours``
  initTimeInterval(hours = h)

proc days*(d: int): TimeInterval {.inline.} =
  ## TimeInterval of ``d`` days.
  ##
  ## ``echo getTime() + 2.days``
  initTimeInterval(days = d)

proc weeks*(w: int): TimeInterval {.inline.} =
  ## TimeInterval of ``w`` weeks.
  ##
  ## ``echo getTime() + 2.weeks``
  initTimeInterval(weeks = w)

proc months*(m: int): TimeInterval {.inline.} =
  ## TimeInterval of ``m`` months.
  ##
  ## ``echo getTime() + 2.months``
  initTimeInterval(months = m)

proc years*(y: int): TimeInterval {.inline.} =
  ## TimeInterval of ``y`` years.
  ##
  ## ``echo getTime() + 2.years``
  initTimeInterval(years = y)

proc evaluateInterval(dt: DateTime, interval: TimeInterval): tuple[adjDur, absDur: Duration] =
  ## Evaluates how many nanoseconds the interval is worth
  ## in the context of ``dt``.
  ## The result in split into an adjusted diff and an absolute diff.
  var months = interval.years * 12 + interval.months
  var curYear = dt.year
  var curMonth = dt.month
  # Subtracting
  if months < 0:
    for mth in countDown(-1 * months, 1):
      if curMonth == mJan:
        curMonth = mDec
        curYear.dec
      else:
        curMonth.dec()
      let days = getDaysInMonth(curMonth, curYear)
      result.adjDur = result.adjDur - initDuration(days = days)
  # Adding
  else:
    for mth in 1 .. months:
      let days = getDaysInMonth(curMonth, curYear)
      result.adjDur = result.adjDur + initDuration(days = days)
      if curMonth == mDec:
        curMonth = mJan
        curYear.inc
      else:
        curMonth.inc()

  result.adjDur = result.adjDur + initDuration(
    days = interval.days,
    weeks = interval.weeks)
  result.absDur = initDuration(
    nanoseconds = interval.nanoseconds,
    microseconds = interval.microseconds,
    milliseconds = interval.milliseconds,
    seconds = interval.seconds,
    minutes = interval.minutes,
    hours = interval.hours)


proc initDateTime*(monthday: MonthdayRange, month: Month, year: int,
                   hour: HourRange, minute: MinuteRange, second: SecondRange,
                   nanosecond: NanosecondRange, zone: Timezone = local()): DateTime =
  ## Create a new ``DateTime`` in the specified timezone.
  runnableExamples:
    let dt1 = initDateTime(30, mMar, 2017, 00, 00, 00, 00, utc())
    doAssert $dt1 == "2017-03-30T00:00:00+00:00"

  assertValidDate monthday, month, year
  let dt = DateTime(
    monthday:  monthday,
    year:  year,
    month:  month,
    hour:  hour,
    minute:  minute,
    second:  second,
    nanosecond: nanosecond
  )
  result = initDateTime(zone.zoneInfoFromTz(dt.toAdjTime), zone)

proc initDateTime*(monthday: MonthdayRange, month: Month, year: int,
                   hour: HourRange, minute: MinuteRange, second: SecondRange,
                   zone: Timezone = local()): DateTime =
  ## Create a new ``DateTime`` in the specified timezone.
  runnableExamples:
    let dt1 = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    doAssert $dt1 == "2017-03-30T00:00:00+00:00"
  initDateTime(monthday, month, year, hour, minute, second, 0, zone)


proc `+`*(dt: DateTime, interval: TimeInterval): DateTime =
  ## Adds ``interval`` to ``dt``. Components from ``interval`` are added
  ## in the order of their size, i.e first the ``years`` component, then the ``months``
  ## component and so on. The returned ``DateTime`` will have the same timezone as the input.
  ##
  ## Note that when adding months, monthday overflow is allowed. This means that if the resulting
  ## month doesn't have enough days it, the month will be incremented and the monthday will be
  ## set to the number of days overflowed. So adding one month to `31 October` will result in `31 November`,
  ## which will overflow and result in `1 December`.
  ##
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    doAssert $(dt + 1.months) == "2017-04-30T00:00:00+00:00"
    # This is correct and happens due to monthday overflow.
    doAssert $(dt - 1.months) == "2017-03-02T00:00:00+00:00"
  let (adjDur, absDur) = evaluateInterval(dt, interval)

  if adjDur != DurationZero:
    var zInfo = dt.timezone.zoneInfoFromTz(dt.toAdjTime + adjDur)
    if absDur != DurationZero:
      let offsetDur = initDuration(seconds = zInfo.utcOffset)
      zInfo = dt.timezone.zoneInfoFromUtc(zInfo.adjTime + offsetDur + absDur)
      result = initDateTime(zInfo, dt.timezone)
    else:
      result = initDateTime(zInfo, dt.timezone)
  else:
    var zInfo = dt.timezone.zoneInfoFromUtc(dt.toTime + absDur)
    result = initDateTime(zInfo, dt.timezone)

proc `-`*(dt: DateTime, interval: TimeInterval): DateTime =
  ## Subtract ``interval`` from ``dt``. Components from ``interval`` are subtracted
  ## in the order of their size, i.e first the ``years`` component, then the ``months``
  ## component and so on. The returned ``DateTime`` will have the same timezone as the input.
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    doAssert $(dt - 5.days) == "2017-03-25T00:00:00+00:00"

  dt + (-interval)

proc `+`*(dt: DateTime, dur: Duration): DateTime =
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    let dur = initDuration(hours = 5)
    doAssert $(dt + dur) == "2017-03-30T05:00:00+00:00"

  (dt.toTime + dur).inZone(dt.timezone)

proc `-`*(dt: DateTime, dur: Duration): DateTime =
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    let dur = initDuration(days = 5)
    doAssert $(dt - dur) == "2017-03-25T00:00:00+00:00"

  (dt.toTime - dur).inZone(dt.timezone)

proc `-`*(dt1, dt2: DateTime): Duration =
  ## Compute the duration between ``dt1`` and ``dt2``.
  runnableExamples:
    let dt1 = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    let dt2 = initDateTime(25, mMar, 2017, 00, 00, 00, utc())

    doAssert dt1 - dt2 == initDuration(days = 5)

  dt1.toTime - dt2.toTime

proc `<`*(a, b: DateTime): bool =
  ## Returns true iff ``a < b``, that is iff a happened before b.
  return a.toTime < b.toTime

proc `<=` * (a, b: DateTime): bool =
  ## Returns true iff ``a <= b``.
  return a.toTime <= b.toTime

proc `==`*(a, b: DateTime): bool =
  ## Returns true if ``a == b``, that is if both dates represent the same point in datetime.
  return a.toTime == b.toTime


proc isStaticInterval(interval: TimeInterval): bool =
  interval.years == 0 and interval.months == 0 and
    interval.days == 0 and interval.weeks == 0

proc evaluateStaticInterval(interval: TimeInterval): Duration =
  assert interval.isStaticInterval
  initDuration(nanoseconds = interval.nanoseconds,
    microseconds = interval.microseconds,
    milliseconds = interval.milliseconds,
    seconds = interval.seconds,
    minutes = interval.minutes,
    hours = interval.hours)

proc between*(startDt, endDt:DateTime): TimeInterval =
  ## Evaluate difference between two dates in ``TimeInterval`` format, so, it
  ## will be relative.
  ##
  ## **Warning:** It's not recommended to use ``between`` for ``DateTime's`` in 
  ## different ``TimeZone's``.  
  ## ``a + between(a, b) == b`` is only guaranteed when ``a`` and ``b`` are in UTC.
  runnableExamples:
    var a = initDateTime(year = 2018, month = Month(3), monthday = 25, 
                     hour = 0, minute = 59, second = 59, nanosecond = 1,
                     zone = utc()).local
    var b = initDateTime(year = 2018, month = Month(3), monthday = 25, 
                     hour = 1, minute =  1, second =  1, nanosecond = 0,
                     zone = utc()).local
    doAssert between(a, b) == initTimeInterval(
      nanoseconds=999, milliseconds=999, microseconds=999, seconds=1, minutes=1)
    
    a = parse("2018-01-09T00:00:00+00:00", "yyyy-MM-dd'T'HH:mm:sszzz", utc())
    b = parse("2018-01-10T23:00:00-02:00", "yyyy-MM-dd'T'HH:mm:sszzz")
    doAssert between(a, b) == initTimeInterval(hours=1, days=2)
    ## Though, here correct answer should be 1 day 25 hours (cause this day in
    ## this tz is actually 26 hours). That's why operating different TZ is
    ## discouraged

  var startDt = startDt.utc()
  var endDt = endDt.utc()

  if endDt == startDt:
    return initTimeInterval()
  elif endDt < startDt:
    return -between(endDt, startDt)

  var coeffs: array[FixedTimeUnit, int64] = unitWeights
  var timeParts: array[FixedTimeUnit, int]
  for unit in Nanoseconds..Weeks:
    timeParts[unit] = 0

  for unit in Seconds..Days:
    coeffs[unit] = coeffs[unit] div unitWeights[Seconds]

  var startTimepart = initTime(
    nanosecond = startDt.nanosecond,
    unix = startDt.hour * coeffs[Hours] + startDt.minute * coeffs[Minutes] +
    startDt.second
  )
  var endTimepart = initTime(
    nanosecond = endDt.nanosecond,
    unix = endDt.hour * coeffs[Hours] + endDt.minute * coeffs[Minutes] +
    endDt.second
  )
  # We wand timeParts for Seconds..Hours be positive, so we'll borrow one day
  if endTimepart < startTimepart:
    timeParts[Days] = -1

  let diffTime = endTimepart - startTimepart
  timeParts[Seconds] = diffTime.seconds.int()
  #Nanoseconds - preliminary count
  timeParts[Nanoseconds] = diffTime.nanoseconds
  for unit in countdown(Milliseconds, Microseconds):
    timeParts[unit] += timeParts[Nanoseconds] div coeffs[unit].int()
    timeParts[Nanoseconds] -= timeParts[unit] * coeffs[unit].int()

  #Counting Seconds .. Hours - final, Days - preliminary
  for unit in countdown(Days, Minutes):
    timeParts[unit] += timeParts[Seconds] div coeffs[unit].int()
    # Here is accounted the borrowed day
    timeParts[Seconds] -= timeParts[unit] * coeffs[unit].int()

  # Set Nanoseconds .. Hours in result
  result.nanoseconds = timeParts[Nanoseconds]
  result.microseconds = timeParts[Microseconds]
  result.milliseconds = timeParts[Milliseconds]
  result.seconds = timeParts[Seconds]
  result.minutes = timeParts[Minutes]
  result.hours = timeParts[Hours]

  #Days
  if endDt.monthday.int + timeParts[Days] < startDt.monthday.int():
    if endDt.month > 1.Month:
      endDt.month -= 1.Month
    else:
      endDt.month = 12.Month
      endDt.year -= 1
    timeParts[Days] += endDt.monthday.int() + getDaysInMonth(
      endDt.month, endDt.year) - startDt.monthday.int()
  else:
    timeParts[Days] += endDt.monthday.int() -
      startDt.monthday.int()

  result.days = timeParts[Days]

  #Months
  if endDt.month < startDt.month:
      result.months = endDt.month.int() + 12 - startDt.month.int()
      endDt.year -= 1
  else:
    result.months = endDt.month.int() -
      startDt.month.int()

  # Years
  result.years = endDt.year - startDt.year

proc `+`*(time: Time, interval: TimeInterval): Time =
  ## Adds `interval` to `time`.
  ## If `interval` contains any years, months, weeks or days the operation
  ## is performed in the local timezone.
  runnableExamples:
    let tm = fromUnix(0)
    doAssert tm + 5.seconds == fromUnix(5)

  if interval.isStaticInterval:
    time + evaluateStaticInterval(interval)
  else:
    toTime(time.local + interval)

proc `-`*(time: Time, interval: TimeInterval): Time =
  ## Subtracts `interval` from Time `time`.
  ## If `interval` contains any years, months, weeks or days the operation
  ## is performed in the local timezone.
  runnableExamples:
    let tm = fromUnix(5)
    doAssert tm - 5.seconds == fromUnix(0)

  if interval.isStaticInterval:
    time - evaluateStaticInterval(interval)
  else:
    toTime(time.local - interval)

proc `+=`*[T, U: TimesMutableTypes](a: var T, b: U) =
  ## Modify ``a`` in place by adding ``b``.
  runnableExamples:
    var tm = fromUnix(0)
    tm += initDuration(seconds = 1)
    doAssert tm == fromUnix(1)
  a = a + b

proc `-=`*[T, U: TimesMutableTypes](a: var T, b: U) =
  ## Modify ``a`` in place by subtracting ``b``.
  runnableExamples:
    var tm = fromUnix(5)
    tm -= initDuration(seconds = 5)
    doAssert tm == fromUnix(0)
  a = a - b

proc `*=`*[T: TimesMutableTypes, U](a: var T, b: U) =
  # Mutable type is often multiplied by number
  runnableExamples:
    var dur = initDuration(seconds = 1)
    dur *= 5
    doAssert dur == initDuration(seconds = 5)

  a = a * b

proc formatToken(dt: DateTime, token: string, buf: var string) =
  ## Helper of the format proc to parse individual tokens.
  ##
  ## Pass the found token in the user input string, and the buffer where the
  ## final string is being built. This has to be a var value because certain
  ## formatting tokens require modifying the previous characters.
  case token
  of "d":
    buf.add($dt.monthday)
  of "dd":
    if dt.monthday < 10:
      buf.add("0")
    buf.add($dt.monthday)
  of "ddd":
    buf.add(($dt.weekday)[0 .. 2])
  of "dddd":
    buf.add($dt.weekday)
  of "h":
    if dt.hour == 0: buf.add("12")
    else: buf.add($(if dt.hour > 12: dt.hour - 12 else: dt.hour))
  of "hh":
    if dt.hour == 0:
      buf.add("12")
    else:
      let amerHour = if dt.hour > 12: dt.hour - 12 else: dt.hour
      if amerHour < 10:
        buf.add('0')
      buf.add($amerHour)
  of "H":
    buf.add($dt.hour)
  of "HH":
    if dt.hour < 10:
      buf.add('0')
    buf.add($dt.hour)
  of "m":
    buf.add($dt.minute)
  of "mm":
    if dt.minute < 10:
      buf.add('0')
    buf.add($dt.minute)
  of "M":
    buf.add($ord(dt.month))
  of "MM":
    if dt.month < mOct:
      buf.add('0')
    buf.add($ord(dt.month))
  of "MMM":
    buf.add(($dt.month)[0..2])
  of "MMMM":
    buf.add($dt.month)
  of "s":
    buf.add($dt.second)
  of "ss":
    if dt.second < 10:
      buf.add('0')
    buf.add($dt.second)
  of "t":
    if dt.hour >= 12:
      buf.add('P')
    else: buf.add('A')
  of "tt":
    if dt.hour >= 12:
      buf.add("PM")
    else: buf.add("AM")
  of "y":
    var fr = ($dt.year).len()-1
    if fr < 0: fr = 0
    buf.add(($dt.year)[fr .. ($dt.year).len()-1])
  of "yy":
    var fr = ($dt.year).len()-2
    if fr < 0: fr = 0
    var fyear = ($dt.year)[fr .. ($dt.year).len()-1]
    if fyear.len != 2: fyear = repeat('0', 2-fyear.len()) & fyear
    buf.add(fyear)
  of "yyy":
    var fr = ($dt.year).len()-3
    if fr < 0: fr = 0
    var fyear = ($dt.year)[fr .. ($dt.year).len()-1]
    if fyear.len != 3: fyear = repeat('0', 3-fyear.len()) & fyear
    buf.add(fyear)
  of "yyyy":
    var fr = ($dt.year).len()-4
    if fr < 0: fr = 0
    var fyear = ($dt.year)[fr .. ($dt.year).len()-1]
    if fyear.len != 4: fyear = repeat('0', 4-fyear.len()) & fyear
    buf.add(fyear)
  of "yyyyy":
    var fr = ($dt.year).len()-5
    if fr < 0: fr = 0
    var fyear = ($dt.year)[fr .. ($dt.year).len()-1]
    if fyear.len != 5: fyear = repeat('0', 5-fyear.len()) & fyear
    buf.add(fyear)
  of "z":
    let
      nonDstTz = dt.utcOffset
      hours = abs(nonDstTz) div secondsInHour
    if nonDstTz <= 0: buf.add('+')
    else: buf.add('-')
    buf.add($hours)
  of "zz":
    let
      nonDstTz = dt.utcOffset
      hours = abs(nonDstTz) div secondsInHour
    if nonDstTz <= 0: buf.add('+')
    else: buf.add('-')
    if hours < 10: buf.add('0')
    buf.add($hours)
  of "zzz":
    let
      nonDstTz = dt.utcOffset
      hours = abs(nonDstTz) div secondsInHour
      minutes = (abs(nonDstTz) div secondsInMin) mod minutesInHour
    if nonDstTz <= 0: buf.add('+')
    else: buf.add('-')
    if hours < 10: buf.add('0')
    buf.add($hours)
    buf.add(':')
    if minutes < 10: buf.add('0')
    buf.add($minutes)
  of "fff":
    buf.add(intToStr(convert(Nanoseconds, Milliseconds, dt.nanosecond), 3))
  of "ffffff":
    buf.add(intToStr(convert(Nanoseconds, Microseconds, dt.nanosecond), 6))
  of "fffffffff":
    buf.add(intToStr(dt.nanosecond, 9))
  of "":
    discard
  else:
    raise newException(ValueError, "Invalid format string: " & token)


proc format*(dt: DateTime, f: string): string {.tags: [].}=
  ## This procedure formats `dt` as specified by `f`. The following format
  ## specifiers are available:
  ##
  ## ============  =================================================================================  ================================================
  ## Specifier     Description                                                                        Example
  ## ============  =================================================================================  ================================================
  ##    d          Numeric value of the day of the month, it will be one or two digits long.          ``1/04/2012 -> 1``, ``21/04/2012 -> 21``
  ##    dd         Same as above, but always two digits.                                              ``1/04/2012 -> 01``, ``21/04/2012 -> 21``
  ##    ddd        Three letter string which indicates the day of the week.                           ``Saturday -> Sat``, ``Monday -> Mon``
  ##    dddd       Full string for the day of the week.                                               ``Saturday -> Saturday``, ``Monday -> Monday``
  ##    h          The hours in one digit if possible. Ranging from 0-12.                             ``5pm -> 5``, ``2am -> 2``
  ##    hh         The hours in two digits always. If the hour is one digit 0 is prepended.           ``5pm -> 05``, ``11am -> 11``
  ##    H          The hours in one digit if possible, randing from 0-24.                             ``5pm -> 17``, ``2am -> 2``
  ##    HH         The hours in two digits always. 0 is prepended if the hour is one digit.           ``5pm -> 17``, ``2am -> 02``
  ##    m          The minutes in 1 digit if possible.                                                ``5:30 -> 30``, ``2:01 -> 1``
  ##    mm         Same as above but always 2 digits, 0 is prepended if the minute is one digit.      ``5:30 -> 30``, ``2:01 -> 01``
  ##    M          The month in one digit if possible.                                                ``September -> 9``, ``December -> 12``
  ##    MM         The month in two digits always. 0 is prepended.                                    ``September -> 09``, ``December -> 12``
  ##    MMM        Abbreviated three-letter form of the month.                                        ``September -> Sep``, ``December -> Dec``
  ##    MMMM       Full month string, properly capitalized.                                           ``September -> September``
  ##    s          Seconds as one digit if possible.                                                  ``00:00:06 -> 6``
  ##    ss         Same as above but always two digits. 0 is prepended.                               ``00:00:06 -> 06``
  ##    t          ``A`` when time is in the AM. ``P`` when time is in the PM.
  ##    tt         Same as above, but ``AM`` and ``PM`` instead of ``A`` and ``P`` respectively.
  ##    y(yyyy)    This displays the year to different digits. You most likely only want 2 or 4 'y's
  ##    yy         Displays the year to two digits.                                                   ``2012 -> 12``
  ##    yyyy       Displays the year to four digits.                                                  ``2012 -> 2012``
  ##    z          Displays the timezone offset from UTC.                                             ``GMT+7 -> +7``, ``GMT-5 -> -5``
  ##    zz         Same as above but with leading 0.                                                  ``GMT+7 -> +07``, ``GMT-5 -> -05``
  ##    zzz        Same as above but with ``:mm`` where *mm* represents minutes.                      ``GMT+7 -> +07:00``, ``GMT-5 -> -05:00``
  ##    fff        Milliseconds display                                                               ``1000000 nanoseconds -> 1``
  ##    ffffff     Microseconds display                                                               ``1000000 nanoseconds -> 1000``
  ##    fffffffff  Nanoseconds display                                                                ``1000000 nanoseconds -> 1000000``
  ## ============  =================================================================================  ================================================
  ##
  ## Other strings can be inserted by putting them in ``''``. For example
  ## ``hh'->'mm`` will give ``01->56``.  The following characters can be
  ## inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]``
  ## ``,``. However you don't need to necessarily separate format specifiers, a
  ## unambiguous format string like ``yyyyMMddhhmmss`` is valid too.
  runnableExamples:
    let dt = initDateTime(01, mJan, 2000, 12, 00, 00, 01, utc())
    doAssert format(dt, "yyyy-MM-dd'T'HH:mm:ss'.'fffffffffzzz") == "2000-01-01T12:00:00.000000001+00:00"

  result = ""
  var i = 0
  var currentF = ""
  while i < f.len:
    case f[i]
    of ' ', '-', '/', ':', '\'', '(', ')', '[', ']', ',':
      formatToken(dt, currentF, result)

      currentF = ""

      if f[i] == '\'':
        inc(i) # Skip '
        while i < f.len-1 and f[i] != '\'':
          result.add(f[i])
          inc(i)
      else: result.add(f[i])

    else:
      # Check if the letter being added matches previous accumulated buffer.
      if currentF.len == 0 or currentF[high(currentF)] == f[i]:
        currentF.add(f[i])
      else:
        formatToken(dt, currentF, result)
        dec(i) # Move position back to re-process the character separately.
        currentF = ""

    inc(i)
  formatToken(dt, currentF, result)

proc format*(time: Time, f: string, zone_info: proc(t: Time): DateTime): string {.tags: [].} =
  ## converts a `Time` value to a string representation. It will use format from
  ## ``format(dt: DateTime, f: string)``.
  runnableExamples:
    var dt = initDateTime(01, mJan, 1970, 00, 00, 00, local())
    var tm = dt.toTime()
    doAssert format(tm, "yyyy-MM-dd'T'HH:mm:ss", local) == "1970-01-01T00:00:00"
    dt = initDateTime(01, mJan, 1970, 00, 00, 00, utc())
    tm = dt.toTime()
    doAssert format(tm, "yyyy-MM-dd'T'HH:mm:ss", utc) == "1970-01-01T00:00:00"

  zone_info(time).format(f)

proc `$`*(dt: DateTime): string {.tags: [], raises: [], benign.} =
  ## Converts a `DateTime` object to a string representation.
  ## It uses the format ``yyyy-MM-dd'T'HH-mm-sszzz``.
  runnableExamples:
    let dt = initDateTime(01, mJan, 2000, 12, 00, 00, utc())
    doAssert $dt == "2000-01-01T12:00:00+00:00"
  try:
    result = format(dt, "yyyy-MM-dd'T'HH:mm:sszzz") # todo: optimize this
  except ValueError: assert false # cannot happen because format string is valid

proc `$`*(time: Time): string {.tags: [], raises: [], benign.} =
  ## converts a `Time` value to a string representation. It will use the local
  ## time zone and use the format ``yyyy-MM-dd'T'HH-mm-sszzz``.
  runnableExamples:
    let dt = initDateTime(01, mJan, 1970, 00, 00, 00, local())
    let tm = dt.toTime()
    doAssert $tm == "1970-01-01T00:00:00" & format(dt, "zzz")
  $time.local

{.pop.}

proc parseToken(dt: var DateTime; token, value: string; j: var int) =
  ## Helper of the parse proc to parse individual tokens.

  # Overwrite system.`[]` to raise a ValueError on index out of bounds.
  proc `[]`[T, U](s: string, x: HSlice[T, U]): string =
    if x.a >= s.len or x.b >= s.len:
      raise newException(ValueError, "Value is missing required tokens, got: " &
                         s)
    return system.`[]`(s, x)

  var sv: int
  case token
  of "d":
    var pd = parseInt(value[j..j+1], sv)
    dt.monthday = sv
    j += pd
  of "dd":
    dt.monthday = value[j..j+1].parseInt()
    j += 2
  of "ddd":
    case value[j..j+2].toLowerAscii()
    of "sun": dt.weekday = dSun
    of "mon": dt.weekday = dMon
    of "tue": dt.weekday = dTue
    of "wed": dt.weekday = dWed
    of "thu": dt.weekday = dThu
    of "fri": dt.weekday = dFri
    of "sat": dt.weekday = dSat
    else:
      raise newException(ValueError,
        "Couldn't parse day of week (ddd), got: " & value[j..j+2])
    j += 3
  of "dddd":
    if value.len >= j+6 and value[j..j+5].cmpIgnoreCase("sunday") == 0:
      dt.weekday = dSun
      j += 6
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("monday") == 0:
      dt.weekday = dMon
      j += 6
    elif value.len >= j+7 and value[j..j+6].cmpIgnoreCase("tuesday") == 0:
      dt.weekday = dTue
      j += 7
    elif value.len >= j+9 and value[j..j+8].cmpIgnoreCase("wednesday") == 0:
      dt.weekday = dWed
      j += 9
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("thursday") == 0:
      dt.weekday = dThu
      j += 8
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("friday") == 0:
      dt.weekday = dFri
      j += 6
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("saturday") == 0:
      dt.weekday = dSat
      j += 8
    else:
      raise newException(ValueError,
        "Couldn't parse day of week (dddd), got: " & value)
  of "h", "H":
    var pd = parseInt(value[j..j+1], sv)
    dt.hour = sv
    j += pd
  of "hh", "HH":
    dt.hour = value[j..j+1].parseInt()
    j += 2
  of "m":
    var pd = parseInt(value[j..j+1], sv)
    dt.minute = sv
    j += pd
  of "mm":
    dt.minute = value[j..j+1].parseInt()
    j += 2
  of "M":
    var pd = parseInt(value[j..j+1], sv)
    dt.month = sv.Month
    j += pd
  of "MM":
    var month = value[j..j+1].parseInt()
    j += 2
    dt.month = month.Month
  of "MMM":
    case value[j..j+2].toLowerAscii():
    of "jan": dt.month = mJan
    of "feb": dt.month = mFeb
    of "mar": dt.month = mMar
    of "apr": dt.month = mApr
    of "may": dt.month = mMay
    of "jun": dt.month = mJun
    of "jul": dt.month = mJul
    of "aug": dt.month = mAug
    of "sep": dt.month = mSep
    of "oct": dt.month = mOct
    of "nov": dt.month = mNov
    of "dec": dt.month = mDec
    else:
      raise newException(ValueError,
        "Couldn't parse month (MMM), got: " & value)
    j += 3
  of "MMMM":
    if value.len >= j+7 and value[j..j+6].cmpIgnoreCase("january") == 0:
      dt.month = mJan
      j += 7
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("february") == 0:
      dt.month = mFeb
      j += 8
    elif value.len >= j+5 and value[j..j+4].cmpIgnoreCase("march") == 0:
      dt.month = mMar
      j += 5
    elif value.len >= j+5 and value[j..j+4].cmpIgnoreCase("april") == 0:
      dt.month = mApr
      j += 5
    elif value.len >= j+3 and value[j..j+2].cmpIgnoreCase("may") == 0:
      dt.month = mMay
      j += 3
    elif value.len >= j+4 and value[j..j+3].cmpIgnoreCase("june") == 0:
      dt.month = mJun
      j += 4
    elif value.len >= j+4 and value[j..j+3].cmpIgnoreCase("july") == 0:
      dt.month = mJul
      j += 4
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("august") == 0:
      dt.month = mAug
      j += 6
    elif value.len >= j+9 and value[j..j+8].cmpIgnoreCase("september") == 0:
      dt.month = mSep
      j += 9
    elif value.len >= j+7 and value[j..j+6].cmpIgnoreCase("october") == 0:
      dt.month = mOct
      j += 7
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("november") == 0:
      dt.month = mNov
      j += 8
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("december") == 0:
      dt.month = mDec
      j += 8
    else:
      raise newException(ValueError,
        "Couldn't parse month (MMMM), got: " & value)
  of "s":
    var pd = parseInt(value[j..j+1], sv)
    dt.second = sv
    j += pd
  of "ss":
    dt.second = value[j..j+1].parseInt()
    j += 2
  of "t":
    if value[j] == 'A' and dt.hour == 12:
      dt.hour = 0
    elif value[j] == 'P' and dt.hour > 0 and dt.hour < 12:
      dt.hour += 12
    j += 1
  of "tt":
    if value[j..j+1] == "AM" and dt.hour == 12:
      dt.hour = 0
    elif value[j..j+1] == "PM" and dt.hour > 0 and dt.hour < 12:
      dt.hour += 12
    j += 2
  of "yy":
    # Assumes current century
    var year = value[j..j+1].parseInt()
    var thisCen = now().year div 100
    dt.year = thisCen*100 + year
    j += 2
  of "yyyy":
    dt.year = value[j..j+3].parseInt()
    j += 4
  of "z":
    dt.isDst = false
    let ch = if j < value.len: value[j] else: '\0'
    if ch == '+':
      dt.utcOffset = 0 - parseInt($value[j+1]) * secondsInHour
    elif ch == '-':
      dt.utcOffset = parseInt($value[j+1]) * secondsInHour
    elif ch == 'Z':
      dt.utcOffset = 0
      j += 1
      return
    else:
      raise newException(ValueError,
        "Couldn't parse timezone offset (z), got: " & ch)
    j += 2
  of "zz":
    dt.isDst = false
    let ch = if j < value.len: value[j] else: '\0'
    if ch == '+':
      dt.utcOffset = 0 - value[j+1..j+2].parseInt() * secondsInHour
    elif ch == '-':
      dt.utcOffset = value[j+1..j+2].parseInt() * secondsInHour
    elif ch == 'Z':
      dt.utcOffset = 0
      j += 1
      return
    else:
      raise newException(ValueError,
        "Couldn't parse timezone offset (zz), got: " & ch)
    j += 3
  of "zzz":
    dt.isDst = false
    var factor = 0
    let ch = if j < value.len: value[j] else: '\0'
    if ch == '+': factor = -1
    elif ch == '-': factor = 1
    elif ch == 'Z':
      dt.utcOffset = 0
      j += 1
      return
    else:
      raise newException(ValueError,
        "Couldn't parse timezone offset (zzz), got: " & ch)
    dt.utcOffset = factor * value[j+1..j+2].parseInt() * secondsInHour
    j += 4
    dt.utcOffset += factor * value[j..j+1].parseInt() * 60
    j += 2
  of "fff", "ffffff", "fffffffff":
    var numStr = ""
    let n = parseWhile(value[j..len(value) - 1], numStr, {'0'..'9'})
    dt.nanosecond = parseInt(numStr) * (10 ^ (9 - n))
    j += n
  else:
    # Ignore the token and move forward in the value string by the same length
    j += token.len

proc parse*(value, layout: string, zone: Timezone = local()): DateTime =
  ## This procedure parses a date/time string using the standard format
  ## identifiers as listed below. The procedure defaults information not provided
  ## in the format string from the running program (month, year, etc).
  ##
  ## The return value will always be in the `zone` timezone. If no UTC offset was
  ## parsed, then the input will be assumed to be specified in the `zone` timezone
  ## already, so no timezone conversion will be done in that case.
  ##
  ## =======================  =================================================================================  ================================================
  ## Specifier                Description                                                                        Example
  ## =======================  =================================================================================  ================================================
  ##    d                     Numeric value of the day of the month, it will be one or two digits long.          ``1/04/2012 -> 1``, ``21/04/2012 -> 21``
  ##    dd                    Same as above, but always two digits.                                              ``1/04/2012 -> 01``, ``21/04/2012 -> 21``
  ##    ddd                   Three letter string which indicates the day of the week.                           ``Saturday -> Sat``, ``Monday -> Mon``
  ##    dddd                  Full string for the day of the week.                                               ``Saturday -> Saturday``, ``Monday -> Monday``
  ##    h                     The hours in one digit if possible. Ranging from 0-12.                             ``5pm -> 5``, ``2am -> 2``
  ##    hh                    The hours in two digits always. If the hour is one digit 0 is prepended.           ``5pm -> 05``, ``11am -> 11``
  ##    H                     The hours in one digit if possible, randing from 0-24.                             ``5pm -> 17``, ``2am -> 2``
  ##    HH                    The hours in two digits always. 0 is prepended if the hour is one digit.           ``5pm -> 17``, ``2am -> 02``
  ##    m                     The minutes in 1 digit if possible.                                                ``5:30 -> 30``, ``2:01 -> 1``
  ##    mm                    Same as above but always 2 digits, 0 is prepended if the minute is one digit.      ``5:30 -> 30``, ``2:01 -> 01``
  ##    M                     The month in one digit if possible.                                                ``September -> 9``, ``December -> 12``
  ##    MM                    The month in two digits always. 0 is prepended.                                    ``September -> 09``, ``December -> 12``
  ##    MMM                   Abbreviated three-letter form of the month.                                        ``September -> Sep``, ``December -> Dec``
  ##    MMMM                  Full month string, properly capitalized.                                           ``September -> September``
  ##    s                     Seconds as one digit if possible.                                                  ``00:00:06 -> 6``
  ##    ss                    Same as above but always two digits. 0 is prepended.                               ``00:00:06 -> 06``
  ##    t                     ``A`` when time is in the AM. ``P`` when time is in the PM.
  ##    tt                    Same as above, but ``AM`` and ``PM`` instead of ``A`` and ``P`` respectively.
  ##    yy                    Displays the year to two digits.                                                   ``2012 -> 12``
  ##    yyyy                  Displays the year to four digits.                                                  ``2012 -> 2012``
  ##    z                     Displays the timezone offset from UTC. ``Z`` is parsed as ``+0``                   ``GMT+7 -> +7``, ``GMT-5 -> -5``
  ##    zz                    Same as above but with leading 0.                                                  ``GMT+7 -> +07``, ``GMT-5 -> -05``
  ##    zzz                   Same as above but with ``:mm`` where *mm* represents minutes.                      ``GMT+7 -> +07:00``, ``GMT-5 -> -05:00``
  ##    fff/ffffff/fffffffff  for consistency with format - nanoseconds                                          ``1 -> 1 nanosecond``
  ## =======================  =================================================================================  ================================================
  ##
  ## Other strings can be inserted by putting them in ``''``. For example
  ## ``hh'->'mm`` will give ``01->56``.  The following characters can be
  ## inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]``
  ## ``,``. However you don't need to necessarily separate format specifiers, a
  ## unambiguous format string like ``yyyyMMddhhmmss`` is valid too.
  runnableExamples:
    let tStr = "1970-01-01T00:00:00.0+00:00"
    doAssert parse(tStr, "yyyy-MM-dd'T'HH:mm:ss.fffzzz") == fromUnix(0).utc

  var i = 0 # pointer for format string
  var j = 0 # pointer for value string
  var token = ""
  # Assumes current day of month, month and year, but time is reset to 00:00:00. Weekday will be reset after parsing.
  var dt = now()
  dt.hour = 0
  dt.minute = 0
  dt.second = 0
  dt.nanosecond = 0
  dt.isDst = true # using this is flag for checking whether a timezone has \
      # been read (because DST is always false when a tz is parsed)
  while i < layout.len:
    case layout[i]
    of ' ', '-', '/', ':', '\'', '(', ')', '[', ']', ',':
      if token.len > 0:
        parseToken(dt, token, value, j)
      # Reset token
      token = ""
      # Skip separator and everything between single quotes
      # These are literals in both the layout and the value string
      if layout[i] == '\'':
        inc(i)
        while i < layout.len-1 and layout[i] != '\'':
          inc(i)
          inc(j)
        inc(i)
      else:
        inc(i)
        inc(j)
    else:
      # Check if the letter being added matches previous accumulated buffer.
      if token.len == 0 or token[high(token)] == layout[i]:
        token.add(layout[i])
        inc(i)
      else:
        parseToken(dt, token, value, j)
        token = ""

  if i >= layout.len and token.len > 0:
    parseToken(dt, token, value, j)
  if dt.isDst:
    # No timezone parsed - assume timezone is `zone`
    result = initDateTime(zone.zoneInfoFromTz(dt.toAdjTime), zone)
  else:
    # Otherwise convert to `zone`
    result = dt.toTime.inZone(zone)

proc parseTime*(value, layout: string, zone: Timezone): Time =
  ## Simple wrapper for parsing string to time
  runnableExamples:
    let tStr = "1970-01-01T00:00:00+00:00"
    doAssert parseTime(tStr, "yyyy-MM-dd'T'HH:mm:sszzz", local()) == fromUnix(0)
  parse(value, layout, zone).toTime()

proc countLeapYears*(yearSpan: int): int =
  ## Returns the number of leap years spanned by a given number of years.
  ##
  ## **Note:** For leap years, start date is assumed to be 1 AD.
  ## counts the number of leap years up to January 1st of a given year.
  ## Keep in mind that if specified year is a leap year, the leap day
  ## has not happened before January 1st of that year.
  (yearSpan - 1) div 4 - (yearSpan - 1) div 100 + (yearSpan - 1) div 400

proc countDays*(yearSpan: int): int =
  ## Returns the number of days spanned by a given number of years.
  (yearSpan - 1) * 365 + countLeapYears(yearSpan)

proc countYears*(daySpan: int): int =
  ## Returns the number of years spanned by a given number of days.
  ((daySpan - countLeapYears(daySpan div 365)) div 365)

proc countYearsAndDays*(daySpan: int): tuple[years: int, days: int] =
  ## Returns the number of years spanned by a given number of days and the
  ## remainder as days.
  let days = daySpan - countLeapYears(daySpan div 365)
  result.years = days div 365
  result.days = days mod 365

proc toTimeInterval*(time: Time): TimeInterval =
  ## Converts a Time to a TimeInterval.
  ##
  ## To be used when diffing times.
  runnableExamples:
    let a = fromUnix(10)
    let dt = initDateTime(01, mJan, 1970, 00, 00, 00, local())
    doAssert a.toTimeInterval() == initTimeInterval(
      years=1970, days=1, seconds=10, hours=convert(
        Seconds, Hours, -dt.utcOffset
      )
    )

  var dt = time.local
  initTimeInterval(dt.nanosecond, 0, 0, dt.second, dt.minute, dt.hour,
    dt.monthday, 0, dt.month.ord - 1, dt.year)

when not defined(JS):
  type
    Clock {.importc: "clock_t".} = distinct int

  proc getClock(): Clock {.importc: "clock", header: "<time.h>", tags: [TimeEffect].}

  var
    clocksPerSec {.importc: "CLOCKS_PER_SEC", nodecl.}: int

  when not defined(useNimRtl):
    proc cpuTime*(): float {.rtl, extern: "nt$1", tags: [TimeEffect].} =
      ## gets time spent that the CPU spent to run the current process in
      ## seconds. This may be more useful for benchmarking than ``epochTime``.
      ## However, it may measure the real time instead (depending on the OS).
      ## The value of the result has no meaning.
      ## To generate useful timing values, take the difference between
      ## the results of two ``cpuTime`` calls:
      runnableExamples:
        var t0 = cpuTime()
        # some useless work here (calculate fibonacci)
        var fib = @[0, 1, 1]
        for i in 1..10:
          fib.add(fib[^1] + fib[^2])
        echo "CPU time [s] ", cpuTime() - t0
        echo "Fib is [s] ", fib
      result = toFloat(int(getClock())) / toFloat(clocksPerSec)

    proc epochTime*(): float {.rtl, extern: "nt$1", tags: [TimeEffect].} =
      ## gets time after the UNIX epoch (1970) in seconds. It is a float
      ## because sub-second resolution is likely to be supported (depending
      ## on the hardware/OS).
      ##
      ## ``getTime`` should generally be prefered over this proc.
      when defined(posix):
        var a: Timeval
        gettimeofday(a)
        result = toBiggestFloat(a.tv_sec.int64) + toFloat(a.tv_usec)*0.00_0001
      elif defined(windows):
        var f: winlean.FILETIME
        getSystemTimeAsFileTime(f)
        var i64 = rdFileTime(f) - epochDiff
        var secs = i64 div rateDiff
        var subsecs = i64 mod rateDiff
        result = toFloat(int(secs)) + toFloat(int(subsecs)) * 0.0000001
      else:
        {.error: "unknown OS".}

when defined(JS):
  proc epochTime*(): float {.tags: [TimeEffect].} =
    newDate().getTime() / 1000

# Deprecated procs

when not defined(JS):
  proc unixTimeToWinTime*(time: CTime): int64 {.deprecated: "Use toWinTime instead".} =
    ## Converts a UNIX `Time` (``time_t``) to a Windows file time
    ##
    ## **Deprecated:** use ``toWinTime`` instead.
    result = int64(time) * rateDiff + epochDiff

  proc winTimeToUnixTime*(time: int64): CTime {.deprecated: "Use fromWinTime instead".} =
    ## Converts a Windows time to a UNIX `Time` (``time_t``)
    ##
    ## **Deprecated:** use ``fromWinTime`` instead.
    result = CTime((time - epochDiff) div rateDiff)

proc initInterval*(seconds, minutes, hours, days, months,
                   years: int = 0): TimeInterval {.deprecated.} =
  ## **Deprecated since v0.18.0:** use ``initTimeInterval`` instead.
  initTimeInterval(0, 0, 0, seconds, minutes, hours, days, 0, months, years)

proc fromSeconds*(since1970: float): Time {.tags: [], raises: [], benign, deprecated.} =
  ## Takes a float which contains the number of seconds since the unix epoch and
  ## returns a time object.
  ##
  ## **Deprecated since v0.18.0:** use ``fromUnix`` instead
  let nanos = ((since1970 - since1970.int64.float) * convert(Seconds, Nanoseconds, 1).float).int
  initTime(since1970.int64, nanos)

proc fromSeconds*(since1970: int64): Time {.tags: [], raises: [], benign, deprecated.} =
  ## Takes an int which contains the number of seconds since the unix epoch and
  ## returns a time object.
  ##
  ## **Deprecated since v0.18.0:** use ``fromUnix`` instead
  fromUnix(since1970)

proc toSeconds*(time: Time): float {.tags: [], raises: [], benign, deprecated.} =
  ## Returns the time in seconds since the unix epoch.
  ##
  ## **Deprecated since v0.18.0:** use ``fromUnix`` instead
  time.seconds.float + time.nanosecond / convert(Seconds, Nanoseconds, 1)

proc getLocalTime*(time: Time): DateTime {.tags: [], raises: [], benign, deprecated.} =
  ## Converts the calendar time `time` to broken-time representation,
  ## expressed relative to the user's specified time zone.
  ##
  ## **Deprecated since v0.18.0:** use ``local`` instead
  time.local

proc getGMTime*(time: Time): DateTime {.tags: [], raises: [], benign, deprecated.} =
  ## Converts the calendar time `time` to broken-down time representation,
  ## expressed in Coordinated Universal Time (UTC).
  ##
  ## **Deprecated since v0.18.0:** use ``utc`` instead
  time.utc

proc getTimezone*(): int {.tags: [TimeEffect], raises: [], benign, deprecated.} =
  ## Returns the offset of the local (non-DST) timezone in seconds west of UTC.
  ##
  ## **Deprecated since v0.18.0:** use ``now().utcOffset`` to get the current
  ## utc offset (including DST).
  when defined(JS):
    return newDate().getTimezoneOffset() * 60
  elif defined(freebsd) or defined(netbsd) or defined(openbsd):
    var a: CTime
    discard time(a)
    let lt = localtime(addr(a))
    # BSD stores in `gmtoff` offset east of UTC in seconds,
    # but posix systems using west of UTC in seconds
    return -(lt.gmtoff)
  else:
    return timezone

proc timeInfoToTime*(dt: DateTime): Time {.tags: [], benign, deprecated.} =
  ## Converts a broken-down time structure to calendar time representation.
  ##
  ## **Deprecated since v0.14.0:** use ``toTime`` instead.
  dt.toTime

when defined(JS):
  var start = getTime()
  proc getStartMilsecs*(): int {.deprecated, tags: [TimeEffect], benign.} =
    ## get the milliseconds from the start of the program.
    ## **Deprecated since v0.8.10:** use ``epochTime`` or ``cpuTime`` instead.
    let dur = getTime() - start
    result = (convert(Seconds, Milliseconds, dur.seconds) +
      convert(Nanoseconds, Milliseconds, dur.nanosecond)).int
else:
  proc getStartMilsecs*(): int {.deprecated, tags: [TimeEffect], benign.} =
    when defined(macosx):
      result = toInt(toFloat(int(getClock())) / (toFloat(clocksPerSec) / 1000.0))
    else:
      result = int(getClock()) div (clocksPerSec div 1000)

proc timeToTimeInterval*(t: Time): TimeInterval {.deprecated.} =
  ## Converts a Time to a TimeInterval.
  ##
  ## **Deprecated since v0.14.0:** use ``toTimeInterval`` instead.
  # Milliseconds not available from Time
  t.toTimeInterval()

proc getDayOfWeek*(day, month, year: int): WeekDay  {.tags: [], raises: [], benign, deprecated.} =
  ## **Deprecated since v0.18.0:** use 
  ## ``getDayOfWeek(monthday: MonthdayRange; month: Month; year: int)`` instead.
  getDayOfWeek(day, month.Month, year)

proc getDayOfWeekJulian*(day, month, year: int): WeekDay {.deprecated.} =
  ## Returns the day of the week enum from day, month and year,
  ## according to the Julian calendar.
  ## **Deprecated since v0.18.0:**
  # Day & month start from one.
  let
    a = (14 - month) div 12
    y = year - a
    m = month + (12*a) - 2
    d = (5 + day + y + (y div 4) + (31*m) div 12) mod 7
  result = d.WeekDay
