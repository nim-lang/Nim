#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##[
  This module contains routines and types for dealing with time using a proleptic Gregorian calendar.
  It's also available for the `JavaScript target <backends.html#the-javascript-target>`_.

  Although the types use nanosecond time resolution, the underlying resolution used by ``getTime()``
  depends on the platform and backend (JS is limited to millisecond precision).

  Examples:

  .. code-block:: nim

    import times, os
    let time = cpuTime()

    sleep(100)   # replace this with something to be timed
    echo "Time taken: ",cpuTime() - time

    echo "My formatted time: ", format(now(), "d MMMM yyyy HH:mm")
    echo "Using predefined formats: ", getClockStr(), " ", getDateStr()

    echo "cpuTime()  float value: ", cpuTime()
    echo "An hour from now      : ", now() + 1.hours
    echo "An hour from (UTC) now: ", getTime().utc + initDuration(hours = 1)

  Parsing and Formatting Dates
  ----------------------------

  The ``DateTime`` type can be parsed and formatted using the different
  ``parse`` and ``format`` procedures.

  .. code-block:: nim

    let dt = parse("2000-01-01", "yyyy-MM-dd")
    echo dt.format("yyyy-MM-dd")

  The different format patterns that are supported are documented below.

  =============  =================================================================================  ================================================
  Pattern        Description                                                                        Example
  =============  =================================================================================  ================================================
  ``d``          Numeric value representing the day of the month,                                   | ``1/04/2012 -> 1``
                 it will be either one or two digits long.                                          | ``21/04/2012 -> 21``
  ``dd``         Same as above, but is always two digits.                                           | ``1/04/2012 -> 01``
                                                                                                    | ``21/04/2012 -> 21``
  ``ddd``        Three letter string which indicates the day of the week.                           | ``Saturday -> Sat``
                                                                                                    | ``Monday -> Mon``
  ``dddd``       Full string for the day of the week.                                               | ``Saturday -> Saturday``
                                                                                                    | ``Monday -> Monday``
  ``h``          The hours in one digit if possible. Ranging from 1-12.                             | ``5pm -> 5``
                                                                                                    | ``2am -> 2``
  ``hh``         The hours in two digits always. If the hour is one digit 0 is prepended.           | ``5pm -> 05``
                                                                                                    | ``11am -> 11``
  ``H``          The hours in one digit if possible, ranging from 0-23.                             | ``5pm -> 17``
                                                                                                    | ``2am -> 2``
  ``HH``         The hours in two digits always. 0 is prepended if the hour is one digit.           | ``5pm -> 17``
                                                                                                    | ``2am -> 02``
  ``m``          The minutes in 1 digit if possible.                                                | ``5:30 -> 30``
                                                                                                    | ``2:01 -> 1``
  ``mm``         Same as above but always 2 digits, 0 is prepended if the minute is one digit.      | ``5:30 -> 30``
                                                                                                    | ``2:01 -> 01``
  ``M``          The month in one digit if possible.                                                | ``September -> 9``
                                                                                                    | ``December -> 12``
  ``MM``         The month in two digits always. 0 is prepended.                                    | ``September -> 09``
                                                                                                    | ``December -> 12``
  ``MMM``        Abbreviated three-letter form of the month.                                        | ``September -> Sep``
                                                                                                    | ``December -> Dec``
  ``MMMM``       Full month string, properly capitalized.                                           | ``September -> September``
  ``s``          Seconds as one digit if possible.                                                  | ``00:00:06 -> 6``
  ``ss``         Same as above but always two digits. 0 is prepended.                               | ``00:00:06 -> 06``
  ``t``          ``A`` when time is in the AM. ``P`` when time is in the PM.                        | ``5pm -> P``
                                                                                                    | ``2am -> A``
  ``tt``         Same as above, but ``AM`` and ``PM`` instead of ``A`` and ``P`` respectively.      | ``5pm -> PM``
                                                                                                    | ``2am -> AM``
  ``yy``         The last two digits of the year. When parsing, the current century is assumed.     | ``2012 AD -> 12``
  ``yyyy``       The year, padded to atleast four digits.                                           | ``2012 AD -> 2012``
                 Is always positive, even when the year is BC.                                      | ``24 AD -> 0024``
                 When the year is more than four digits, '+' is prepended.                          | ``24 BC -> 00024``
                                                                                                    | ``12345 AD -> +12345``
  ``YYYY``       The year without any padding.                                                      | ``2012 AD -> 2012``
                 Is always positive, even when the year is BC.                                      | ``24 AD -> 24``
                                                                                                    | ``24 BC -> 24``
                                                                                                    | ``12345 AD -> 12345``
  ``uuuu``       The year, padded to atleast four digits. Will be negative when the year is BC.     | ``2012 AD -> 2012``
                 When the year is more than four digits, '+' is prepended unless the year is BC.    | ``24 AD -> 0024``
                                                                                                    | ``24 BC -> -0023``
                                                                                                    | ``12345 AD -> +12345``
  ``UUUU``       The year without any padding. Will be negative when the year is BC.                | ``2012 AD -> 2012``
                                                                                                    | ``24 AD -> 24``
                                                                                                    | ``24 BC -> -23``
                                                                                                    | ``12345 AD -> 12345``
  ``z``          Displays the timezone offset from UTC.                                             | ``GMT+7 -> +7``
                                                                                                    | ``GMT-5 -> -5``
  ``zz``         Same as above but with leading 0.                                                  | ``GMT+7 -> +07``
                                                                                                    | ``GMT-5 -> -05``
  ``zzz``        Same as above but with ``:mm`` where *mm* represents minutes.                      | ``GMT+7 -> +07:00``
                                                                                                    | ``GMT-5 -> -05:00``
  ``zzzz``       Same as above but with ``:ss`` where *ss* represents seconds.                      | ``GMT+7 -> +07:00:00``
                                                                                                    | ``GMT-5 -> -05:00:00``
  ``g``          Era: AD or BC                                                                      | ``300 AD -> AD``
                                                                                                    | ``300 BC -> BC``
  ``fff``        Milliseconds display                                                               | ``1000000 nanoseconds -> 1``
  ``ffffff``     Microseconds display                                                               | ``1000000 nanoseconds -> 1000``
  ``fffffffff``  Nanoseconds display                                                                | ``1000000 nanoseconds -> 1000000``
  =============  =================================================================================  ================================================

  Other strings can be inserted by putting them in ``''``. For example
  ``hh'->'mm`` will give ``01->56``.  The following characters can be
  inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]``
  ``,``. A literal ``'`` can be specified with ``''``.

  However you don't need to necessarily separate format patterns, a
  unambiguous format string like ``yyyyMMddhhmmss`` is valid too (although
  only for years in the range 1..9999).
]##


{.push debugger:off.} # the user does not want to trace a part
                      # of the standard library!

import
  strutils, parseutils, algorithm, math, options, strformat

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
    mJan = (1, "January")
    mFeb = "February"
    mMar = "March"
    mApr = "April"
    mMay = "May"
    mJun = "June"
    mJul = "July"
    mAug = "August"
    mSep = "September"
    mOct = "October"
    mNov = "November"
    mDec = "December"

  WeekDay* = enum ## Represents a weekday.
    dMon = "Monday"
    dTue = "Tuesday"
    dWed = "Wednesday"
    dThu = "Thursday"
    dFri = "Friday"
    dSat = "Saturday"
    dSun = "Sunday"

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

  Timezone* = ref object ## \
      ## Timezone interface for supporting ``DateTime``'s of arbritary
      ## timezones. The ``times`` module only supplies implementations for the
      ## systems local time and UTC.
    zonedTimeFromTimeImpl: proc (x: Time): ZonedTime
        {.tags: [], raises: [], benign.}
    zonedTimeFromAdjTimeImpl: proc (x: Time): ZonedTime
        {.tags: [], raises: [], benign.}
    name: string

  ZonedTime* = object ## Represents a point in time with an associated
                      ## UTC offset and DST flag. This type is only used for
                      ## implementing timezones.
    time*: Time     ## The point in time being represented.
    utcOffset*: int ## The offset in seconds west of UTC,
                    ## including any offset due to DST.
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
proc utcTzInfo(time: Time): ZonedTime {.tags: [], raises: [], benign .}
proc localZonedTimeFromTime(time: Time): ZonedTime {.tags: [], raises: [], benign .}
proc localZonedTimeFromAdjTime(adjTime: Time): ZonedTime {.tags: [], raises: [], benign .}
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
    doAssert $fromUnix(0).utc == "1970-01-01T00:00:00Z"
  initTime(unix, 0)

proc toUnix*(t: Time): int64 {.benign, tags: [], raises: [], noSideEffect.} =
  ## Convert ``t`` to a unix timestamp (seconds since ``1970-01-01T00:00:00Z``).
  runnableExamples:
    doAssert fromUnix(0).toUnix() == 0
  t.seconds

proc fromWinTime*(win: int64): Time =
  ## Convert a Windows file time (100-nanosecond intervals since ``1601-01-01T00:00:00Z``)
  ## to a ``Time``.
  const hnsecsPerSec = convert(Seconds, Nanoseconds, 1) div 100
  let nanos = floorMod(win, hnsecsPerSec) * 100
  let seconds = floorDiv(win - epochDiff, hnsecsPerSec)
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
  ## Equivalent with ``initDateTime(monthday, month, year, 0, 0, 0).yearday``.
  assertValidDate monthday, month, year
  const daysUntilMonth:     array[Month, int] = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  const daysUntilMonthLeap: array[Month, int] = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]

  if isLeapYear(year):
    result = daysUntilMonthLeap[month] + monthday - 1
  else:
    result = daysUntilMonth[month] + monthday - 1

proc getDayOfWeek*(monthday: MonthdayRange, month: Month, year: int): WeekDay {.tags: [], raises: [], benign .} =
  ## Returns the day of the week enum from day, month and year.
  ## Equivalent with ``initDateTime(monthday, month, year, 0, 0, 0).weekday``.
  assertValidDate monthday, month, year
  # 1970-01-01 is a Thursday, we adjust to the previous Monday
  let days = toEpochday(monthday, month, year) - 3
  let weeks = floorDiv(days, 7)
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

proc stringifyUnit(value: int | int64, unit: TimeUnit): string =
  ## Stringify time unit with it's name, lowercased
  let strUnit = $unit
  result = ""
  result.add($value)
  result.add(" ")
  if abs(value) != 1:
    result.add(strUnit.toLowerAscii())
  else:
    result.add(strUnit[0..^2].toLowerAscii())

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
    for i in 0..high(parts)-1:
      result.add parts[i] & ", "
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
      parts.add(stringifyUnit(quantity, unit))

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
  seconds.inc dt.utcOffset
  result = initTime(seconds, dt.nanosecond)

proc initDateTime(zt: ZonedTime, zone: Timezone): DateTime =
  ## Create a new ``DateTime`` using ``ZonedTime`` in the specified timezone.
  let adjTime = zt.time - initDuration(seconds = zt.utcOffset)
  let s = adjTime.seconds
  let epochday = floorDiv(s, secondsInDay)
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
    nanosecond: zt.time.nanosecond,
    weekday: getDayOfWeek(d, m, y),
    yearday: getDayOfYear(d, m, y),
    isDst: zt.isDst,
    timezone: zone,
    utcOffset: zt.utcOffset
  )

proc newTimezone*(
      name: string,
      zonedTimeFromTimeImpl: proc (time: Time): ZonedTime {.tags: [], raises: [], benign.},
      zonedTimeFromAdjTimeImpl:  proc (adjTime: Time): ZonedTime {.tags: [], raises: [], benign.}
    ): Timezone =
  ## Create a new ``Timezone``.
  ##
  ## ``zonedTimeFromTimeImpl`` and ``zonedTimeFromAdjTimeImpl`` is used
  ## as the underlying implementations for ``zonedTimeFromTime`` and
  ## ``zonedTimeFromAdjTime``.
  ##
  ## If possible, the name parameter should match the name used in the
  ## tz database. If the timezone doesn't exist in the tz database, or if the
  ## timezone name is unknown, then any string that describes the timezone
  ## unambiguously can be used. Note that the timezones name is used for
  ## checking equality!
  runnableExamples:
    proc utcTzInfo(time: Time): ZonedTime =
      ZonedTime(utcOffset: 0, isDst: false, time: time)
    let utc = newTimezone("Etc/UTC", utcTzInfo, utcTzInfo)
  Timezone(
    name: name,
    zonedTimeFromTimeImpl: zonedTimeFromTimeImpl,
    zonedTimeFromAdjTimeImpl: zonedTimeFromAdjTimeImpl
  )

proc name*(zone: Timezone): string =
  ## The name of the timezone.
  ##
  ## If possible, the name will be the name used in the tz database.
  ## If the timezone doesn't exist in the tz database, or if the timezone
  ## name is unknown, then any string that describes the timezone
  ## unambiguously might be used. For example, the string "LOCAL" is used
  ## for the systems local timezone.
  ##
  ## See also: https://en.wikipedia.org/wiki/Tz_database
  zone.name

proc zonedTimeFromTime*(zone: Timezone, time: Time): ZonedTime =
  ## Returns the ``ZonedTime`` for some point in time.
  zone.zonedTimeFromTimeImpl(time)

proc zonedTimeFromAdjTime*(zone: TimeZone, adjTime: Time): ZonedTime =
  ## Returns the ``ZonedTime`` for some local time.
  ##
  ## Note that the ``Time`` argument does not represent a point in time, it
  ## represent a local time! E.g if ``adjTime`` is ``fromUnix(0)``, it should be
  ## interpreted as 1970-01-01T00:00:00 in the ``zone`` timezone, not in UTC.
  zone.zonedTimeFromAdjTimeImpl(adjTime)

proc `$`*(zone: Timezone): string =
  ## Returns the name of the timezone.
  zone.name

proc `==`*(zone1, zone2: Timezone): bool =
  ## Two ``Timezone``'s are considered equal if their name is equal.
  runnableExamples:
    doAssert local() == local()
    doAssert local() != utc()
  zone1.name == zone2.name

proc inZone*(time: Time, zone: Timezone): DateTime {.tags: [], raises: [], benign.} =
  ## Convert ``time`` into a ``DateTime`` using ``zone`` as the timezone.
  result = initDateTime(zone.zonedTimeFromTime(time), zone)

proc inZone*(dt: DateTime, zone: Timezone): DateTime  {.tags: [], raises: [], benign.} =
  ## Returns a ``DateTime`` representing the same point in time as ``dt`` but
  ## using ``zone`` as the timezone.
  dt.toTime.inZone(zone)

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

    proc localZonedTimeFromTime(time: Time): ZonedTime =
      let jsDate = newDate(time.seconds.float * 1000)
      let offset = jsDate.getTimezoneOffset() * secondsInMin
      result.time = time
      result.utcOffset = offset
      result.isDst = false

    proc localZonedTimeFromAdjTime(adjTime: Time): ZonedTime =
      let utcDate = newDate(adjTime.seconds.float * 1000)
      let localDate = newDate(utcDate.getUTCFullYear(), utcDate.getUTCMonth(), utcDate.getUTCDate(),
        utcDate.getUTCHours(), utcDate.getUTCMinutes(), utcDate.getUTCSeconds(), 0)

      # This is as dumb as it looks - JS doesn't support years in the range 0-99 in the constructor
      # because they are assumed to be 19xx...
      # Because JS doesn't support timezone history, it doesn't really matter in practice.
      if utcDate.getUTCFullYear() in 0 .. 99:
        localDate.setFullYear(utcDate.getUTCFullYear())

      result.utcOffset = localDate.getTimezoneOffset() * secondsInMin
      result.time = adjTime + initDuration(seconds = result.utcOffset)
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
        when defined(linux) and defined(amd64) or defined(haiku):
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
    # Windows can't handle unix < 0, so we fall back to unix = 0.
    # FIXME: This should be improved by falling back to the WinAPI instead.
    when defined(windows):
      if unix < 0:
        var a = 0.CTime
        let tmPtr = localtime(addr(a))
        if not tmPtr.isNil:
          let tm = tmPtr[]
          return ((0 - tm.toAdjUnix).int, false)
        return (0, false)

    # In case of a 32-bit time_t, we fallback to the closest available
    # timezone information.
    var a = clamp(unix, low(CTime), high(CTime)).CTime
    let tmPtr = localtime(addr(a))
    if not tmPtr.isNil:
      let tm = tmPtr[]
      return ((a.int64 - tm.toAdjUnix).int, tm.isdst > 0)
    return (0, false)

  proc localZonedTimeFromTime(time: Time): ZonedTime =
    let (offset, dst) = getLocalOffsetAndDst(time.seconds)
    result.time = time
    result.utcOffset = offset
    result.isDst = dst

  proc localZonedTimeFromAdjTime(adjTime: Time): ZonedTime  =
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
    result.time = initTime(utcUnix, adjTime.nanosecond)
    result.utcOffset = finalOffset
    result.isDst = dst

proc utcTzInfo(time: Time): ZonedTime =
  ZonedTime(utcOffset: 0, isDst: false, time: time)

var utcInstance {.threadvar.}: Timezone
var localInstance {.threadvar.}: Timezone

proc utc*(): TimeZone =
  ## Get the ``Timezone`` implementation for the UTC timezone.
  runnableExamples:
    doAssert now().utc.timezone == utc()
    doAssert utc().name == "Etc/UTC"
  if utcInstance.isNil:
    utcInstance = newTimezone("Etc/UTC", utcTzInfo, utcTzInfo)
  result = utcInstance

proc local*(): TimeZone =
  ## Get the ``Timezone`` implementation for the local timezone.
  runnableExamples:
   doAssert now().timezone == local()
   doAssert local().name == "LOCAL"
  if localInstance.isNil:
    localInstance = newTimezone("LOCAL", localZonedTimeFromTime,
      localZonedTimeFromAdjTime)
  result = localInstance

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
    doAssert $(dt + day) == "2000-01-02T12:00:00Z"
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
      parts.add(stringifyUnit(tiParts[unit], unit))

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
    doAssert $dt1 == "2017-03-30T00:00:00Z"

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
  result = initDateTime(zone.zonedTimeFromAdjTime(dt.toAdjTime), zone)

proc initDateTime*(monthday: MonthdayRange, month: Month, year: int,
                   hour: HourRange, minute: MinuteRange, second: SecondRange,
                   zone: Timezone = local()): DateTime =
  ## Create a new ``DateTime`` in the specified timezone.
  runnableExamples:
    let dt1 = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    doAssert $dt1 == "2017-03-30T00:00:00Z"
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
    doAssert $(dt + 1.months) == "2017-04-30T00:00:00Z"
    # This is correct and happens due to monthday overflow.
    doAssert $(dt - 1.months) == "2017-03-02T00:00:00Z"
  let (adjDur, absDur) = evaluateInterval(dt, interval)

  if adjDur != DurationZero:
    var zt = dt.timezone.zonedTimeFromAdjTime(dt.toAdjTime + adjDur)
    if absDur != DurationZero:
      zt = dt.timezone.zonedTimeFromTime(zt.time + absDur)
      result = initDateTime(zt, dt.timezone)
    else:
      result = initDateTime(zt, dt.timezone)
  else:
    var zt = dt.timezone.zonedTimeFromTime(dt.toTime + absDur)
    result = initDateTime(zt, dt.timezone)

proc `-`*(dt: DateTime, interval: TimeInterval): DateTime =
  ## Subtract ``interval`` from ``dt``. Components from ``interval`` are subtracted
  ## in the order of their size, i.e first the ``years`` component, then the ``months``
  ## component and so on. The returned ``DateTime`` will have the same timezone as the input.
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    doAssert $(dt - 5.days) == "2017-03-25T00:00:00Z"

  dt + (-interval)

proc `+`*(dt: DateTime, dur: Duration): DateTime =
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    let dur = initDuration(hours = 5)
    doAssert $(dt + dur) == "2017-03-30T05:00:00Z"

  (dt.toTime + dur).inZone(dt.timezone)

proc `-`*(dt: DateTime, dur: Duration): DateTime =
  runnableExamples:
    let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
    let dur = initDuration(days = 5)
    doAssert $(dt - dur) == "2017-03-25T00:00:00Z"

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
  ## Returns true if ``a == b``, that is if both dates represent the same point in time.
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

proc between*(startDt, endDt: DateTime): TimeInterval =
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

#
# Parse & format implementation
#

type
  AmPm = enum
    apUnknown, apAm, apPm

  Era = enum
    eraUnknown, eraAd, eraBc

  ParsedTime = object
    amPm: AmPm
    era: Era
    year: Option[int]
    month: Option[int]
    monthday: Option[int]
    utcOffset: Option[int]

    # '0' as default for these work fine
    # so no need for `Option`.
    hour: int
    minute: int
    second: int
    nanosecond: int

  FormatTokenKind = enum
    tkPattern, tkLiteral

  FormatPattern {.pure.} = enum
    d, dd, ddd, dddd
    h, hh, H, HH
    m, mm, M, MM, MMM, MMMM
    s, ss
    fff, ffffff, fffffffff
    t, tt
    y, yy, yyy, yyyy, yyyyy
    YYYY
    uuuu
    UUUU
    z, zz, zzz, zzzz
    g

    # This is a special value used to mark literal format values.
    # See the doc comment for ``TimeFormat.patterns``.
    Lit

  TimeFormat* = object ## Represents a format for parsing and printing
                       ## time types.
    patterns: seq[byte] ## \
      ## Contains the patterns encoded as bytes.
      ## Literal values are encoded in a special way.
      ## They start with ``Lit.byte``, then the length of the literal, then the
      ## raw char values of the literal. For example, the literal `foo` would
      ## be encoded as ``@[Lit.byte, 3.byte, 'f'.byte, 'o'.byte, 'o'.byte]``.
    formatStr: string

const FormatLiterals = { ' ', '-', '/', ':', '(', ')', '[', ']', ',' }

proc `$`*(f: TimeFormat): string =
  ## Returns the format string that was used to construct ``f``.
  runnableExamples:
    let f = initTimeFormat("yyyy-MM-dd")
    doAssert $f == "yyyy-MM-dd"
  f.formatStr

proc raiseParseException(f: TimeFormat, input: string, msg: string) =
  raise newException(ValueError,
                     &"Failed to parse '{input}' with format '{f}'. {msg}")

iterator tokens(f: string): tuple[kind: FormatTokenKind, token: string] =
  var i = 0
  var currToken = ""

  template yieldCurrToken() =
    if currToken.len != 0:
      yield (tkPattern, currToken)
      currToken = ""

  while i < f.len:
    case f[i]
    of '\'':
      yieldCurrToken()
      if i.succ < f.len and f[i.succ] == '\'':
        yield (tkLiteral, "'")
        i.inc 2
      else:
        var token = ""
        inc(i) # Skip '
        while i < f.len and f[i] != '\'':
          token.add f[i]
          i.inc

        if i > f.high:
          raise newException(ValueError,
                             &"Unclosed ' in time format string. " &
                             "For a literal ', use ''.")
        i.inc
        yield (tkLiteral, token)
    of FormatLiterals:
        yieldCurrToken()
        yield (tkLiteral, $f[i])
        i.inc
    else:
      # Check if the letter being added matches previous accumulated buffer.
      if currToken.len == 0 or currToken[0] == f[i]:
        currToken.add(f[i])
        i.inc
      else:
        yield (tkPattern, currToken)
        currToken = $f[i]
        i.inc

  yieldCurrToken()

proc stringToPattern(str: string): FormatPattern =
  case str
  of "d": result = d
  of "dd": result = dd
  of "ddd": result = ddd
  of "dddd": result = dddd
  of "h": result = h
  of "hh": result = hh
  of "H": result = H
  of "HH": result = HH
  of "m": result = m
  of "mm": result = mm
  of "M": result = M
  of "MM": result = MM
  of "MMM": result = MMM
  of "MMMM": result = MMMM
  of "s": result = s
  of "ss": result = ss
  of "fff": result = fff
  of "ffffff": result = ffffff
  of "fffffffff": result = fffffffff
  of "t": result = t
  of "tt": result = tt
  of "y": result = y
  of "yy": result = yy
  of "yyy": result = yyy
  of "yyyy": result = yyyy
  of "yyyyy": result = yyyyy
  of "YYYY": result = YYYY
  of "uuuu": result = uuuu
  of "UUUU": result = UUUU
  of "z": result = z
  of "zz": result = zz
  of "zzz": result = zzz
  of "zzzz": result = zzzz
  of "g": result = g
  else: raise newException(ValueError, &"'{str}' is not a valid pattern")

proc initTimeFormat*(format: string): TimeFormat =
  ## Construct a new time format for parsing & formatting time types.
  ##
  ## See `Parsing and formatting dates`_ for documentation of the
  ## ``format`` argument.
  runnableExamples:
    let f = initTimeFormat("yyyy-MM-dd")
    doAssert "2000-01-01" == "2000-01-01".parse(f).format(f)
  result.formatStr = format
  result.patterns = @[]
  for kind, token in format.tokens:
    case kind
    of tkLiteral:
      case token
      else:
        result.patterns.add(FormatPattern.Lit.byte)
        if token.len > 255:
          raise newException(ValueError,
                             "Format literal is to long:" & token)
        result.patterns.add(token.len.byte)
        for c in token:
          result.patterns.add(c.byte)
    of tkPattern:
      result.patterns.add(stringToPattern(token).byte)

proc formatPattern(dt: DateTime, pattern: FormatPattern, result: var string) =
  template yearOfEra(dt: DateTime): int =
    if dt.year <= 0: abs(dt.year) + 1 else: dt.year

  case pattern
  of d:
    result.add $dt.monthday
  of dd:
    result.add dt.monthday.intToStr(2)
  of ddd:
    result.add ($dt.weekday)[0..2]
  of dddd:
    result.add $dt.weekday
  of h:
    result.add(
      if dt.hour == 0:   "12"
      elif dt.hour > 12: $(dt.hour - 12)
      else:              $dt.hour
    )
  of hh:
    result.add(
      if dt.hour == 0:   "12"
      elif dt.hour > 12: (dt.hour - 12).intToStr(2)
      else:              dt.hour.intToStr(2)
    )
  of H:
    result.add $dt.hour
  of HH:
    result.add dt.hour.intToStr(2)
  of m:
    result.add $dt.minute
  of mm:
    result.add dt.minute.intToStr(2)
  of M:
    result.add $ord(dt.month)
  of MM:
    result.add ord(dt.month).intToStr(2)
  of MMM:
    result.add ($dt.month)[0..2]
  of MMMM:
    result.add $dt.month
  of s:
    result.add $dt.second
  of ss:
    result.add dt.second.intToStr(2)
  of fff:
    result.add(intToStr(convert(Nanoseconds, Milliseconds, dt.nanosecond), 3))
  of ffffff:
    result.add(intToStr(convert(Nanoseconds, Microseconds, dt.nanosecond), 6))
  of fffffffff:
    result.add(intToStr(dt.nanosecond, 9))
  of t:
    result.add if dt.hour >= 12: "P" else: "A"
  of tt:
    result.add if dt.hour >= 12: "PM" else: "AM"
  of y: # Deprecated
    result.add $(dt.yearOfEra mod 10)
  of yy:
    result.add (dt.yearOfEra mod 100).intToStr(2)
  of yyy: # Deprecated
    result.add (dt.yearOfEra mod 1000).intToStr(3)
  of yyyy:
    let year = dt.yearOfEra
    if year < 10000:
      result.add year.intToStr(4)
    else:
      result.add '+' & $year
  of yyyyy: # Deprecated
    result.add (dt.yearOfEra mod 100_000).intToStr(5)
  of YYYY:
    if dt.year < 1:
      result.add $(abs(dt.year) + 1)
    else:
      result.add $dt.year
  of uuuu:
    let year = dt.year
    if year < 10000 or year < 0:
      result.add year.intToStr(4)
    else:
      result.add '+' & $year
  of UUUU:
      result.add $dt.year
  of z, zz, zzz, zzzz:
    if dt.timezone.name == "Etc/UTC":
      result.add 'Z'
    else:
      result.add  if -dt.utcOffset >= 0: '+' else: '-'
      let absOffset = abs(dt.utcOffset)
      case pattern:
      of z:
        result.add $(absOffset div 3600)
      of zz:
        result.add (absOffset div 3600).intToStr(2)
      of zzz:
        let h = (absOffset div 3600).intToStr(2)
        let m = ((absOffset div 60) mod 60).intToStr(2)
        result.add h & ":" & m
      of zzzz:
        let absOffset = abs(dt.utcOffset)
        let h = (absOffset div 3600).intToStr(2)
        let m = ((absOffset div 60) mod 60).intToStr(2)
        let s = (absOffset mod 60).intToStr(2)
        result.add h & ":" & m & ":" & s
      else: assert false
  of g:
      result.add if dt.year < 1: "BC" else: "AD"
  of Lit: assert false # Can't happen

proc parsePattern(input: string, pattern: FormatPattern, i: var int,
                  parsed: var ParsedTime): bool =
  template takeInt(allowedWidth: Slice[int]): int =
    var sv: int
    let max = i + allowedWidth.b - 1
    var pd =
      if max > input.high:
        parseInt(input, sv, i)
      else:
        parseInt(input[i..max], sv)
    if pd notin allowedWidth:
      return false
    i.inc pd
    sv

  template contains[T](t: typedesc[T], i: int): bool =
    i in low(t)..high(t)

  result = true

  case pattern
  of d:
    parsed.monthday = some(takeInt(1..2))
    result = parsed.monthday.get() in MonthdayRange
  of dd:
    parsed.monthday = some(takeInt(2..2))
    result = parsed.monthday.get() in MonthdayRange
  of ddd:
    result = input.substr(i, i+2).toLowerAscii() in [
      "sun", "mon", "tue", "wed", "thu", "fri", "sat"]
    if result:
      i.inc 3
  of dddd:
    if input.substr(i, i+5).cmpIgnoreCase("sunday") == 0:
      i.inc 6
    elif input.substr(i, i+5).cmpIgnoreCase("monday") == 0:
      i.inc 6
    elif input.substr(i, i+6).cmpIgnoreCase("tuesday") == 0:
      i.inc 7
    elif input.substr(i, i+8).cmpIgnoreCase("wednesday") == 0:
      i.inc 9
    elif input.substr(i, i+7).cmpIgnoreCase("thursday") == 0:
      i.inc 8
    elif input.substr(i, i+5).cmpIgnoreCase("friday") == 0:
      i.inc 6
    elif input.substr(i, i+7).cmpIgnoreCase("saturday") == 0:
      i.inc 8
    else:
      result = false
  of h, H:
    parsed.hour = takeInt(1..2)
    result = parsed.hour in HourRange
  of hh, HH:
    parsed.hour = takeInt(2..2)
    result = parsed.hour in HourRange
  of m:
    parsed.minute = takeInt(1..2)
    result = parsed.hour in MinuteRange
  of mm:
    parsed.minute = takeInt(2..2)
    result = parsed.hour in MinuteRange
  of M:
    let month = takeInt(1..2)
    result = month in 1..12
    parsed.month = some(month)
  of MM:
    let month = takeInt(2..2)
    result = month in 1..12
    parsed.month = some(month)
  of MMM:
    case input.substr(i, i+2).toLowerAscii()
    of "jan": parsed.month = some(1)
    of "feb": parsed.month = some(2)
    of "mar": parsed.month = some(3)
    of "apr": parsed.month = some(4)
    of "may": parsed.month = some(5)
    of "jun": parsed.month = some(6)
    of "jul": parsed.month = some(7)
    of "aug": parsed.month = some(8)
    of "sep": parsed.month = some(9)
    of "oct": parsed.month = some(10)
    of "nov": parsed.month = some(11)
    of "dec": parsed.month = some(12)
    else:
      result = false
    if result:
      i.inc 3
  of MMMM:
    if input.substr(i, i+6).cmpIgnoreCase("january") == 0:
      parsed.month = some(1)
      i.inc 7
    elif input.substr(i, i+7).cmpIgnoreCase("february") == 0:
      parsed.month = some(2)
      i.inc 8
    elif input.substr(i, i+4).cmpIgnoreCase("march") == 0:
      parsed.month = some(3)
      i.inc 5
    elif input.substr(i, i+4).cmpIgnoreCase("april") == 0:
      parsed.month = some(4)
      i.inc 5
    elif input.substr(i, i+2).cmpIgnoreCase("may") == 0:
      parsed.month = some(5)
      i.inc 3
    elif input.substr(i, i+3).cmpIgnoreCase("june") == 0:
      parsed.month = some(6)
      i.inc 4
    elif input.substr(i, i+3).cmpIgnoreCase("july") == 0:
      parsed.month = some(7)
      i.inc 4
    elif input.substr(i, i+5).cmpIgnoreCase("august") == 0:
      parsed.month = some(8)
      i.inc 6
    elif input.substr(i, i+8).cmpIgnoreCase("september") == 0:
      parsed.month = some(9)
      i.inc 9
    elif input.substr(i, i+6).cmpIgnoreCase("october") == 0:
      parsed.month = some(10)
      i.inc 7
    elif input.substr(i, i+7).cmpIgnoreCase("november") == 0:
      parsed.month = some(11)
      i.inc 8
    elif input.substr(i, i+7).cmpIgnoreCase("december") == 0:
      parsed.month = some(12)
      i.inc 8
    else:
      result = false
  of s:
    parsed.second = takeInt(1..2)
  of ss:
    parsed.second = takeInt(2..2)
  of fff, ffffff, fffffffff:
    let len = ($pattern).len
    let v = takeInt(len..len)
    parsed.nanosecond = v * 10^(9 - len)
    result = parsed.nanosecond in NanosecondRange
  of t:
    case input[i]:
    of 'P':
      parsed.amPm = apPm
    of 'A':
      parsed.amPm = apAm
    else:
      result = false
    i.inc 1
  of tt:
    if input.substr(i, i+1).cmpIgnoreCase("AM") == 0:
      parsed.amPm = apAM
      i.inc 2
    elif input.substr(i, i+1).cmpIgnoreCase("PM") == 0:
      parsed.amPm = apPm
      i.inc 2
    else:
      result = false
  of yy:
    # Assumes current century
    var year = takeInt(2..2)
    var thisCen = now().year div 100
    parsed.year = some(thisCen*100 + year)
    result = year > 0
  of yyyy:
    let year =
      if input[i] in { '+', '-' }:
        takeInt(4..high(int))
      else:
        takeInt(4..4)
    result = year > 0
    parsed.year = some(year)
  of YYYY:
    let year = takeInt(1..high(int))
    parsed.year = some(year)
    result = year > 0
  of uuuu:
    let year =
      if input[i] in { '+', '-' }:
        takeInt(4..high(int))
      else:
        takeInt(4..4)
    parsed.year = some(year)
  of UUUU:
    parsed.year = some(takeInt(1..high(int)))
  of z, zz, zzz, zzzz:
    case input[i]
    of '+', '-':
      let sign = if input[i] == '-': 1 else: -1
      i.inc
      var offset = 0
      case pattern
      of z:
        offset = takeInt(1..2) * -3600
      of zz:
        offset = takeInt(2..2) * -3600
      of zzz:
        offset.inc takeInt(2..2) * 3600
        if input[i] != ':':
          return false
        i.inc
        offset.inc takeInt(2..2) * 60
      of zzzz:
        offset.inc takeInt(2..2) * 3600
        if input[i] != ':':
          return false
        i.inc
        offset.inc takeInt(2..2) * 60
        if input[i] != ':':
          return false
        i.inc
        offset.inc takeInt(2..2)
      else: assert false
      parsed.utcOffset = some(offset * sign)
    of 'Z':
      parsed.utcOffset = some(0)
      i.inc
    else:
      result = false
  of g:
    if input.substr(i, i+1).cmpIgnoreCase("BC") == 0:
      parsed.era = eraBc
      i.inc 2
    elif input.substr(i, i+1).cmpIgnoreCase("AD") == 0:
      parsed.era = eraAd
      i.inc 2
    else:
      result = false
  of y, yyy, yyyyy:
    raise newException(ValueError,
                      &"The pattern '{pattern}' is only valid for formatting")
  of Lit: assert false # Can't happen

proc toDateTime(p: ParsedTime, zone: Timezone, f: TimeFormat,
                input: string): DateTime =
  var month = mJan
  var year: int
  var monthday: int
  # `now()` is an expensive call, so we avoid it when possible
  (year, month, monthday) =
    if p.year.isNone or p.month.isNone or p.monthday.isNone:
      let n = now()
      (p.year.get(n.year),
        p.month.get(n.month.int).Month,
        p.monthday.get(n.monthday))
    else:
      (p.year.get(), p.month.get().Month, p.monthday.get())

  year =
    case p.era
    of eraUnknown:
      year
    of eraBc:
      if year < 1:
        raiseParseException(f, input,
          "Expected year to be positive " &
          "(use 'UUUU' or 'uuuu' for negative years).")
      -year + 1
    of eraAd:
      if year < 1:
        raiseParseException(f, input,
          "Expected year to be positive " &
          "(use 'UUUU' or 'uuuu' for negative years).")
      year

  let hour =
    case p.amPm
    of apUnknown:
      p.hour
    of apAm:
      if p.hour notin 1..12:
        raiseParseException(f, input,
          "AM/PM time must be in the interval 1..12")
      if p.hour == 12: 0 else: p.hour
    of apPm:
      if p.hour notin 1..12:
        raiseParseException(f, input,
          "AM/PM time must be in the interval 1..12")
      if p.hour == 12: p.hour else: p.hour + 12
  let minute = p.minute
  let second = p.second
  let nanosecond = p.nanosecond

  if monthday > getDaysInMonth(month, year):
    raiseParseException(f, input,
      $year & "-" & ord(month).intToStr(2) &
      "-" & $monthday & " is not a valid date")

  result = DateTime(
    year: year, month: month, monthday: monthday,
    hour: hour, minute: minute, second: second, nanosecond: nanosecond
  )

  if p.utcOffset.isNone:
    # No timezone parsed - assume timezone is `zone`
    result = initDateTime(zone.zonedTimeFromAdjTime(result.toAdjTime), zone)
  else:
    # Otherwise convert to `zone`
    result.utcOffset = p.utcOffset.get()
    result = result.toTime.inZone(zone)

proc format*(dt: DateTime, f: TimeFormat): string {.raises: [].} =
  ## Format ``dt`` using the format specified by ``f``.
  runnableExamples:
    let f = initTimeFormat("yyyy-MM-dd")
    let dt = initDateTime(01, mJan, 2000, 00, 00, 00, utc())
    doAssert "2000-01-01" == dt.format(f)
  var idx = 0
  while idx <= f.patterns.high:
    case f.patterns[idx].FormatPattern
    of Lit:
      idx.inc
      let len = f.patterns[idx]
      for i in 1'u8..len:
        idx.inc
        result.add f.patterns[idx].char
      idx.inc
    else:
      formatPattern(dt, f.patterns[idx].FormatPattern, result = result)
      idx.inc

proc format*(dt: DateTime, f: string): string =
  ## Shorthand for constructing a ``TimeFormat`` and using it to format ``dt``.
  ##
  ## See `Parsing and formatting dates`_ for documentation of the
  ## ``format`` argument.
  runnableExamples:
    let dt = initDateTime(01, mJan, 2000, 00, 00, 00, utc())
    doAssert "2000-01-01" == format(dt, "yyyy-MM-dd")
  let dtFormat = initTimeFormat(f)
  result = dt.format(dtFormat)

proc format*(dt: DateTime, f: static[string]): string {.raises: [].} =
  ## Overload that validates ``format`` at compile time.
  const f2 = initTimeFormat(f)
  result = dt.format(f2)

proc format*(time: Time, f: string, zone: Timezone = local()): string {.tags: [].} =
  ## Shorthand for constructing a ``TimeFormat`` and using it to format
  ## ``time``. Will use the timezone specified by ``zone``.
  ##
  ## See `Parsing and formatting dates`_ for documentation of the
  ## ``f`` argument.
  runnableExamples:
    var dt = initDateTime(01, mJan, 1970, 00, 00, 00, utc())
    var tm = dt.toTime()
    doAssert format(tm, "yyyy-MM-dd'T'HH:mm:ss", utc()) == "1970-01-01T00:00:00"
  time.inZone(zone).format(f)

proc format*(time: Time, f: static[string],
             zone: Timezone = local()): string {.tags: [].} =
  ## Overload that validates ``f`` at compile time.
  const f2 = initTimeFormat(f)
  result = time.inZone(zone).format(f2)

proc parse*(input: string, f: TimeFormat, zone: Timezone = local()): DateTime =
  ## Parses ``input`` as a ``DateTime`` using the format specified by ``f``.
  ## If no UTC offset was parsed, then ``input`` is assumed to be specified in
  ## the ``zone`` timezone. If a UTC offset was parsed, the result will be
  ## converted to the ``zone`` timezone.
  runnableExamples:
    let f = initTimeFormat("yyyy-MM-dd")
    let dt = initDateTime(01, mJan, 2000, 00, 00, 00, utc())
    doAssert dt == "2000-01-01".parse(f, utc())
  var inpIdx = 0 # Input index
  var patIdx = 0 # Pattern index
  var parsed: ParsedTime
  while inpIdx <= input.high and patIdx <= f.patterns.high:
    let pattern = f.patterns[patIdx].FormatPattern
    case pattern
    of Lit:
      patIdx.inc
      let len = f.patterns[patIdx]
      patIdx.inc
      for _ in 1'u8..len:
        if input[inpIdx] != f.patterns[patIdx].char:
          raiseParseException(f, input,
                              "Unexpected character: " & input[inpIdx])
        inpIdx.inc
        patIdx.inc
    else:
      if not parsePattern(input, pattern, inpIdx, parsed):
        raiseParseException(f, input, &"Failed on pattern '{pattern}'")
      patIdx.inc

  if inpIdx <= input.high:
    raiseParseException(f, input,
                        "Parsing ended but there was still input remaining")

  if patIdx <= f.patterns.high:
    raiseParseException(f, input,
                        "Parsing ended but there was still patterns remaining")

  result = toDateTime(parsed, zone, f, input)

proc parse*(input, f: string, tz: Timezone = local()): DateTime =
  ## Shorthand for constructing a ``TimeFormat`` and using it to parse
  ## ``input`` as a ``DateTime``.
  ##
  ## See `Parsing and formatting dates`_ for documentation of the
  ## ``f`` argument.
  runnableExamples:
    let dt = initDateTime(01, mJan, 2000, 00, 00, 00, utc())
    doAssert dt == parse("2000-01-01", "yyyy-MM-dd", utc())
  let dtFormat = initTimeFormat(f)
  result = input.parse(dtFormat, tz)

proc parse*(input: string, f: static[string], zone: Timezone = local()): DateTime =
  ## Overload that validates ``f`` at compile time.
  const f2 = initTimeFormat(f)
  result = input.parse(f2, zone)

proc parseTime*(input, f: string, zone: Timezone): Time =
  ## Shorthand for constructing a ``TimeFormat`` and using it to parse
  ## ``input`` as a ``DateTime``, then converting it a ``Time``.
  ##
  ## See `Parsing and formatting dates`_ for documentation of the
  ## ``format`` argument.
  runnableExamples:
    let tStr = "1970-01-01T00:00:00+00:00"
    doAssert parseTime(tStr, "yyyy-MM-dd'T'HH:mm:sszzz", utc()) == fromUnix(0)
  parse(input, f, zone).toTime()

proc parseTime*(input: string, f: static[string], zone: Timezone): Time =
  ## Overload that validates ``format`` at compile time.
  const f2 = initTimeFormat(f)
  result = input.parse(f2, zone).toTime()

#
# End of parse & format implementation
#

proc `$`*(dt: DateTime): string {.tags: [], raises: [], benign.} =
  ## Converts a `DateTime` object to a string representation.
  ## It uses the format ``yyyy-MM-dd'T'HH-mm-sszzz``.
  runnableExamples:
    let dt = initDateTime(01, mJan, 2000, 12, 00, 00, utc())
    doAssert $dt == "2000-01-01T12:00:00Z"
  result = format(dt, "yyyy-MM-dd'T'HH:mm:sszzz")

proc `$`*(time: Time): string {.tags: [], raises: [], benign.} =
  ## converts a `Time` value to a string representation. It will use the local
  ## time zone and use the format ``yyyy-MM-dd'T'HH-mm-sszzz``.
  runnableExamples:
    let dt = initDateTime(01, mJan, 1970, 00, 00, 00, local())
    let tm = dt.toTime()
    doAssert $tm == "1970-01-01T00:00:00" & format(dt, "zzz")
  $time.local

{.pop.}

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
  ## To be used when diffing times. Consider using `between` instead.
  runnableExamples:
    let a = fromUnix(10)
    let b = fromUnix(1_500_000_000)
    let ti = b.toTimeInterval() - a.toTimeInterval()
    doAssert a + ti == b
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
  ## **Deprecated since v0.18.0:** use ``toUnix`` instead
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
    let dur = getTime() - start
    result = (convert(Seconds, Milliseconds, dur.seconds) +
      convert(Nanoseconds, Milliseconds, dur.nanosecond)).int
else:
  proc getStartMilsecs*(): int {.deprecated, tags: [TimeEffect], benign.} =
    ## get the milliseconds from the start of the program.
    ##
    ## **Deprecated since v0.8.10:** use ``epochTime`` or ``cpuTime`` instead.
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
  ## **Deprecated since v0.18.0**
  # Day & month start from one.
  let
    a = (14 - month) div 12
    y = year - a
    m = month + (12*a) - 2
    d = (5 + day + y + (y div 4) + (31*m) div 12) mod 7
  result = d.WeekDay

proc adjTime*(zt: ZonedTime): Time
    {.deprecated: "Use zt.time instead".} =
  ## **Deprecated since v0.19.0:** use the ``time`` field instead.
  zt.time - initDuration(seconds = zt.utcOffset)

proc `adjTime=`*(zt: var ZonedTime, adjTime: Time)
    {.deprecated: "Use zt.time instead".} =
  ## **Deprecated since v0.19.0:** use the ``time`` field instead.
  zt.time = adjTime + initDuration(seconds = zt.utcOffset)

proc zoneInfoFromUtc*(zone: Timezone, time: Time): ZonedTime
    {.deprecated: "Use zonedTimeFromTime instead".} =
  ## **Deprecated since v0.19.0:** use ``zonedTimeFromTime`` instead.
  zone.zonedTimeFromTime(time)

proc zoneInfoFromTz*(zone: Timezone, adjTime: Time): ZonedTime
    {.deprecated: "Use zonedTimeFromAdjTime instead".} =
  ## **Deprecated since v0.19.0:** use the ``zonedTimeFromAdjTime`` instead.
  zone.zonedTimeFromAdjTime(adjTime)