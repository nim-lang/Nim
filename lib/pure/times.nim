#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time.
## This module is available for the `JavaScript target
## <backends.html#the-javascript-target>`_. The proleptic Gregorian calendar is the only calendar supported.
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
##  echo "epochTime() float value: ", epochTime()
##  echo "cpuTime()   float value: ", cpuTime()
##  echo "An hour from now      : ", now() + 1.hours
##  echo "An hour from (UTC) now: ", getTime().utc + initInterval(0,0,0,1)

{.push debugger:off.} # the user does not want to trace a part
                      # of the standard library!

import
  strutils, parseutils

include "system/inclrtl"

when defined(posix):
  import posix

  type CTime = posix.Time

  proc posix_gettimeofday(tp: var Timeval, unused: pointer = nil) {.
    importc: "gettimeofday", header: "<sys/time.h>".}

  when not defined(freebsd) and not defined(netbsd) and not defined(openbsd):
    var timezone {.importc, header: "<time.h>".}: int
    tzset()

elif defined(windows):
  import winlean

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

  TimeImpl = int64

  Time* = distinct TimeImpl ## Represents a point in time.
                            ## This is currently implemented as a ``int64`` representing
                            ## seconds since ``1970-01-01T00:00:00Z``, but don't
                            ## rely on this knowledge because it might change
                            ## in the future to allow for higher precision.
                            ## Use the procs ``toUnix`` and ``fromUnix`` to
                            ## work with unix timestamps instead.

  DateTime* = object of RootObj ## Represents a time in different parts.
                                ## Although this type can represent leap
                                ## seconds, they are generally not supported
                                ## in this module. They are not ignored,
                                ## but the ``DateTime``'s returned by
                                ## procedures in this module will never have
                                ## a leap second.
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

  TimeInterval* = object ## Represents a duration of time. Can be used to add and subtract
                         ## from a ``DateTime`` or ``Time``.
                         ## Note that a ``TimeInterval`` doesn't represent a fixed duration of time,
                         ## since the duration of some units depend on the context (e.g a year
                         ## can be either 365 or 366 days long). The non-fixed time units are years,
                         ## months and days.
    milliseconds*: int ## The number of milliseconds
    seconds*: int     ## The number of seconds
    minutes*: int     ## The number of minutes
    hours*: int       ## The number of hours
    days*: int        ## The number of days
    months*: int      ## The number of months
    years*: int       ## The number of years

  Timezone* = object ## Timezone interface for supporting ``DateTime``'s of arbritary timezones.
                     ## The ``times`` module only supplies implementations for the systems local time and UTC.
                     ## The members ``zoneInfoFromUtc`` and ``zoneInfoFromTz`` should not be accessed directly
                     ## and are only exported so that ``Timezone`` can be implemented by other modules.
    zoneInfoFromUtc*: proc (time: Time): ZonedTime {.tags: [], raises: [], benign.}
    zoneInfoFromTz*:  proc (adjTime: Time): ZonedTime {.tags: [], raises: [], benign.}
    name*: string ## The name of the timezone, f.ex 'Europe/Stockholm' or 'Etc/UTC'. Used for checking equality.
                  ## Se also: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  ZonedTime* = object ## Represents a zooned instant in time that is not associated with any calendar.
                      ## This type is only used for implementing timezones.
    adjTime*: Time ## Time adjusted to a timezone.
    utcOffset*: int
    isDst*: bool

{.deprecated: [TMonth: Month, TWeekDay: WeekDay, TTime: Time,
    TTimeInterval: TimeInterval, TTimeInfo: DateTime, TimeInfo: DateTime].}

const
  secondsInMin = 60
  secondsInHour = 60*60
  secondsInDay = 60*60*24
  minutesInHour = 60

proc fromUnix*(unix: int64): Time {.benign, tags: [], raises: [], noSideEffect.} =
  ## Convert a unix timestamp (seconds since ``1970-01-01T00:00:00Z``) to a ``Time``.
  Time(unix)

proc toUnix*(t: Time): int64 {.benign, tags: [], raises: [], noSideEffect.} =
  ## Convert ``t`` to a unix timestamp (seconds since ``1970-01-01T00:00:00Z``).
  t.int64

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
    $year & "-" & $ord(month) & "-" & $monthday & " is not a valid date"

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

# Forward declarations
proc utcZoneInfoFromUtc(time: Time): ZonedTime {.tags: [], raises: [], benign .}
proc utcZoneInfoFromTz(adjTime: Time): ZonedTime {.tags: [], raises: [], benign .}
proc localZoneInfoFromUtc(time: Time): ZonedTime {.tags: [], raises: [], benign .}
proc localZoneInfoFromTz(adjTime: Time): ZonedTime {.tags: [], raises: [], benign .}

proc `-`*(a, b: Time): int64 {.
    rtl, extern: "ntDiffTime", tags: [], raises: [], noSideEffect, benign, deprecated.} =
  ## Computes the difference of two calendar times. Result is in seconds.
  ## This is deprecated because it will need to change when sub second time resolution is implemented.
  ## Use ``a.toUnix - b.toUnix`` instead.
  ##
  ## .. code-block:: nim
  ##     let a = fromSeconds(1_000_000_000)
  ##     let b = fromSeconds(1_500_000_000)
  ##     echo initInterval(seconds=int(b - a))
  ##     # (milliseconds: 0, seconds: 20, minutes: 53, hours: 0, days: 5787, months: 0, years: 0)
  a.toUnix - b.toUnix

proc `<`*(a, b: Time): bool {.
    rtl, extern: "ntLtTime", tags: [], raises: [], noSideEffect, borrow.}
  ## Returns true iff ``a < b``, that is iff a happened before b.

proc `<=` * (a, b: Time): bool {.
    rtl, extern: "ntLeTime", tags: [], raises: [], noSideEffect, borrow.}
  ## Returns true iff ``a <= b``.

proc `==`*(a, b: Time): bool {.
    rtl, extern: "ntEqTime", tags: [], raises: [], noSideEffect, borrow.}
  ## Returns true if ``a == b``, that is if both times represent the same point in time.

proc toTime*(dt: DateTime): Time {.tags: [], raises: [], benign.} =
  ## Converts a broken-down time structure to
  ## calendar time representation.
  let epochDay = toEpochday(dt.monthday, dt.month, dt.year)
  result = Time(epochDay * secondsInDay)
  result.inc dt.hour * secondsInHour
  result.inc dt.minute * 60
  result.inc dt.second
  # The code above ignores the UTC offset of `timeInfo`,
  # so we need to compensate for that here.
  result.inc dt.utcOffset

proc `<`*(a, b: DateTime): bool =
  ## Returns true iff ``a < b``, that is iff a happened before b.
  return a.toTime < b.toTime

proc `<=` * (a, b: DateTime): bool =
  ## Returns true iff ``a <= b``.
  return a.toTime <= b.toTime

proc `==`*(a, b: DateTime): bool =
  ## Returns true if ``a == b``, that is if both dates represent the same point in datetime.
  return a.toTime == b.toTime

proc initDateTime(zt: ZonedTime, zone: Timezone): DateTime =
  let adjTime = zt.adjTime.int64
  let epochday = (if adjTime >= 0: adjTime else: adjTime - (secondsInDay - 1)) div secondsInDay
  var rem = zt.adjTime.int64 - epochday * secondsInDay
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
  result = Time(epochDay * secondsInDay)
  result.inc dt.hour * secondsInHour
  result.inc dt.minute * secondsInMin
  result.inc dt.second

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
      let jsDate = newDate(time.float * 1000)
      let offset = jsDate.getTimezoneOffset() * secondsInMin
      result.adjTime = Time(time.int64 - offset)
      result.utcOffset = offset
      result.isDst = false

    proc localZoneInfoFromTz(adjTime: Time): ZonedTime =
      let utcDate = newDate(adjTime.float * 1000)
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

  proc toAdjTime(tm: StructTm): Time =
    let epochDay = toEpochday(tm.monthday, (tm.month + 1).Month, tm.year.int + 1900)
    result = Time(epochDay * secondsInDay)
    result.inc tm.hour * secondsInHour
    result.inc tm.minute * 60
    result.inc tm.second

  proc getStructTm(time: Time | int64): StructTm =
    let timei64 = time.int64
    var a =
      if timei64 < low(CTime):
        CTime(low(CTime))
      elif timei64 > high(CTime):
        CTime(high(CTime))
      else:
        CTime(timei64)
    result = localtime(addr(a))[]

  proc localZoneInfoFromUtc(time: Time): ZonedTime =
    let tm = getStructTm(time)
    let adjTime = tm.toAdjTime
    result.adjTime = adjTime
    result.utcOffset = (time.toUnix - adjTime.toUnix).int
    result.isDst = tm.isdst > 0

  proc localZoneInfoFromTz(adjTime: Time): ZonedTime  =
    var adjTimei64 = adjTime.int64
    let past = adjTimei64 - secondsInDay
    var tm = getStructTm(past)
    let pastOffset = past - tm.toAdjTime.int64

    let future = adjTimei64 + secondsInDay
    tm = getStructTm(future)
    let futureOffset = future - tm.toAdjTime.int64

    var utcOffset: int
    if pastOffset == futureOffset:
        utcOffset = pastOffset.int
    else:
      if pastOffset > futureOffset:
        adjTimei64 -= secondsInHour

      adjTimei64 += pastOffset
      utcOffset = (adjTimei64 - getStructTm(adjTimei64).toAdjTime.int64).int

    # This extra roundtrip is needed to normalize any impossible datetimes
    # as a result of offset changes (normally due to dst)
    let utcTime = adjTime.int64 + utcOffset
    tm = getStructTm(utcTime)
    result.adjTime = tm.toAdjTime
    result.utcOffset = (utcTime - result.adjTime.int64).int
    result.isDst = tm.isdst > 0

proc utcZoneInfoFromUtc(time: Time): ZonedTime =
  result.adjTime = time
  result.utcOffset = 0
  result.isDst = false

proc utcZoneInfoFromTz(adjTime: Time): ZonedTime =
  utcZoneInfoFromUtc(adjTime) # adjTime == time since we are in UTC

proc utc*(): TimeZone =
  ## Get the ``Timezone`` implementation for the UTC timezone.
  ##
  ## .. code-block:: nim
  ##  doAssert now().utc.timezone == utc()
  ##  doAssert utc().name == "Etc/UTC"
  Timezone(zoneInfoFromUtc: utcZoneInfoFromUtc, zoneInfoFromTz: utcZoneInfoFromTz, name: "Etc/UTC")

proc local*(): TimeZone =
  ## Get the ``Timezone`` implementation for the local timezone.
  ##
  ## .. code-block:: nim
  ##  doAssert now().timezone == local()
  ##  doAssert local().name == "LOCAL"
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

proc getTime*(): Time {.tags: [TimeEffect], benign.}
  ## Gets the current time as a ``Time`` with second resolution. Use epochTime for higher
  ## resolution.

proc now*(): DateTime {.tags: [TimeEffect], benign.} =
  ## Get the current time as a  ``DateTime`` in the local timezone.
  ##
  ## Shorthand for ``getTime().local``.
  getTime().local

proc initInterval*(milliseconds, seconds, minutes, hours, days, months,
                   years: int = 0): TimeInterval =
  ## Creates a new ``TimeInterval``.
  ##
  ## You can also use the convenience procedures called ``milliseconds``,
  ## ``seconds``, ``minutes``, ``hours``, ``days``, ``months``, and ``years``.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##     let day = initInterval(hours=24)
  ##     let dt = initDateTime(01, mJan, 2000, 12, 00, 00, utc())
  ##     doAssert $(dt + day) == "2000-01-02T12-00-00+00:00"
  result.milliseconds = milliseconds
  result.seconds = seconds
  result.minutes = minutes
  result.hours = hours
  result.days = days
  result.months = months
  result.years = years

proc `+`*(ti1, ti2: TimeInterval): TimeInterval =
  ## Adds two ``TimeInterval`` objects together.
  result.milliseconds = ti1.milliseconds + ti2.milliseconds
  result.seconds = ti1.seconds + ti2.seconds
  result.minutes = ti1.minutes + ti2.minutes
  result.hours = ti1.hours + ti2.hours
  result.days = ti1.days + ti2.days
  result.months = ti1.months + ti2.months
  result.years = ti1.years + ti2.years

proc `-`*(ti: TimeInterval): TimeInterval =
  ## Reverses a time interval
  ##
  ## .. code-block:: nim
  ##
  ##     let day = -initInterval(hours=24)
  ##     echo day  # -> (milliseconds: 0, seconds: 0, minutes: 0, hours: -24, days: 0, months: 0, years: 0)
  result = TimeInterval(
    milliseconds: -ti.milliseconds,
    seconds: -ti.seconds,
    minutes: -ti.minutes,
    hours: -ti.hours,
    days: -ti.days,
    months: -ti.months,
    years: -ti.years
  )

proc `-`*(ti1, ti2: TimeInterval): TimeInterval =
  ## Subtracts TimeInterval ``ti1`` from ``ti2``.
  ##
  ## Time components are compared one-by-one, see output:
  ##
  ## .. code-block:: nim
  ##     let a = fromUnix(1_000_000_000)
  ##     let b = fromUnix(1_500_000_000)
  ##     echo b.toTimeInterval - a.toTimeInterval
  ##     # (milliseconds: 0, seconds: -40, minutes: -6, hours: 1, days: 5, months: -2, years: 16)
  result = ti1 + (-ti2)

proc evaluateInterval(dt: DateTime, interval: TimeInterval): tuple[adjDiff, absDiff: int64] =
  ## Evaluates how many seconds the interval is worth
  ## in the context of ``dt``.
  ## The result in split into an adjusted diff and an absolute diff.

  var anew = dt
  var newinterv = interval

  newinterv.months += interval.years * 12
  var curMonth = anew.month
  # Subtracting
  if newinterv.months < 0:
    for mth in countDown(-1 * newinterv.months, 1):
      if curMonth == mJan:
        curMonth = mDec
        anew.year.dec()
      else:
        curMonth.dec()
      result.adjDiff -= getDaysInMonth(curMonth, anew.year) * secondsInDay
  # Adding
  else:
    for mth in 1 .. newinterv.months:
      result.adjDiff += getDaysInMonth(curMonth, anew.year) * secondsInDay
      if curMonth == mDec:
        curMonth = mJan
        anew.year.inc()
      else:
        curMonth.inc()
  result.adjDiff += newinterv.days * secondsInDay
  result.absDiff += newinterv.hours * secondsInHour
  result.absDiff += newinterv.minutes * secondsInMin
  result.absDiff += newinterv.seconds
  result.absDiff += newinterv.milliseconds div 1000

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
  ## .. code-block:: nim
  ##  let dt = initDateTime(30, mMar, 2017, 00, 00, 00, utc())
  ##  doAssert $(dt + 1.months) == "2017-04-30T00:00:00+00:00"
  ##  # This is correct and happens due to monthday overflow.
  ##  doAssert $(dt - 1.months) == "2017-03-02T00:00:00+00:00"
  let (adjDiff, absDiff) = evaluateInterval(dt, interval)

  if adjDiff.int64 != 0:
    let zInfo = dt.timezone.zoneInfoFromTz(Time(dt.toAdjTime.int64 + adjDiff))

    if absDiff != 0:
      let time = Time(zInfo.adjTime.int64 + zInfo.utcOffset + absDiff)
      result = initDateTime(dt.timezone.zoneInfoFromUtc(time), dt.timezone)
    else:
      result = initDateTime(zInfo, dt.timezone)
  else:
    result = initDateTime(dt.timezone.zoneInfoFromUtc(Time(dt.toTime.int64 + absDiff)), dt.timezone)

proc `-`*(dt: DateTime, interval: TimeInterval): DateTime =
  ## Subtract ``interval`` from ``dt``. Components from ``interval`` are subtracted
  ## in the order of their size, i.e first the ``years`` component, then the ``months``
  ## component and so on. The returned ``DateTime`` will have the same timezone as the input.
  dt + (-interval)

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

proc milliseconds*(ms: int): TimeInterval {.inline.} =
  ## TimeInterval of `ms` milliseconds
  ##
  ## Note: not all time procedures have millisecond resolution
  initInterval(milliseconds = ms)

proc seconds*(s: int): TimeInterval {.inline.} =
  ## TimeInterval of `s` seconds
  ##
  ## ``echo getTime() + 5.second``
  initInterval(seconds = s)

proc minutes*(m: int): TimeInterval {.inline.} =
  ## TimeInterval of `m` minutes
  ##
  ## ``echo getTime() + 5.minutes``
  initInterval(minutes = m)

proc hours*(h: int): TimeInterval {.inline.} =
  ## TimeInterval of `h` hours
  ##
  ## ``echo getTime() + 2.hours``
  initInterval(hours = h)

proc days*(d: int): TimeInterval {.inline.} =
  ## TimeInterval of `d` days
  ##
  ## ``echo getTime() + 2.days``
  initInterval(days = d)

proc months*(m: int): TimeInterval {.inline.} =
  ## TimeInterval of `m` months
  ##
  ## ``echo getTime() + 2.months``
  initInterval(months = m)

proc years*(y: int): TimeInterval {.inline.} =
  ## TimeInterval of `y` years
  ##
  ## ``echo getTime() + 2.years``
  initInterval(years = y)

proc `+=`*(time: var Time, interval: TimeInterval) =
  ## Modifies `time` by adding `interval`.
  time = toTime(time.local + interval)

proc `+`*(time: Time, interval: TimeInterval): Time =
  ## Adds `interval` to `time`
  ## by converting to a ``DateTime`` in the local timezone,
  ## adding the interval, and converting back to ``Time``.
  ##
  ## ``echo getTime() + 1.day``
  result = toTime(time.local + interval)

proc `-=`*(time: var Time, interval: TimeInterval) =
  ## Modifies `time` by subtracting `interval`.
  time = toTime(time.local - interval)

proc `-`*(time: Time, interval: TimeInterval): Time =
  ## Subtracts `interval` from Time `time`.
  ##
  ## ``echo getTime() - 1.day``
  result = toTime(time.local - interval)

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
    buf.add($(if dt.hour > 12: dt.hour - 12 else: dt.hour))
  of "hh":
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
  of "":
    discard
  else:
    raise newException(ValueError, "Invalid format string: " & token)


proc format*(dt: DateTime, f: string): string {.tags: [].}=
  ## This procedure formats `dt` as specified by `f`. The following format
  ## specifiers are available:
  ##
  ## ==========  =================================================================================  ================================================
  ## Specifier   Description                                                                        Example
  ## ==========  =================================================================================  ================================================
  ##    d        Numeric value of the day of the month, it will be one or two digits long.          ``1/04/2012 -> 1``, ``21/04/2012 -> 21``
  ##    dd       Same as above, but always two digits.                                              ``1/04/2012 -> 01``, ``21/04/2012 -> 21``
  ##    ddd      Three letter string which indicates the day of the week.                           ``Saturday -> Sat``, ``Monday -> Mon``
  ##    dddd     Full string for the day of the week.                                               ``Saturday -> Saturday``, ``Monday -> Monday``
  ##    h        The hours in one digit if possible. Ranging from 0-12.                             ``5pm -> 5``, ``2am -> 2``
  ##    hh       The hours in two digits always. If the hour is one digit 0 is prepended.           ``5pm -> 05``, ``11am -> 11``
  ##    H        The hours in one digit if possible, randing from 0-24.                             ``5pm -> 17``, ``2am -> 2``
  ##    HH       The hours in two digits always. 0 is prepended if the hour is one digit.           ``5pm -> 17``, ``2am -> 02``
  ##    m        The minutes in 1 digit if possible.                                                ``5:30 -> 30``, ``2:01 -> 1``
  ##    mm       Same as above but always 2 digits, 0 is prepended if the minute is one digit.      ``5:30 -> 30``, ``2:01 -> 01``
  ##    M        The month in one digit if possible.                                                ``September -> 9``, ``December -> 12``
  ##    MM       The month in two digits always. 0 is prepended.                                    ``September -> 09``, ``December -> 12``
  ##    MMM      Abbreviated three-letter form of the month.                                        ``September -> Sep``, ``December -> Dec``
  ##    MMMM     Full month string, properly capitalized.                                           ``September -> September``
  ##    s        Seconds as one digit if possible.                                                  ``00:00:06 -> 6``
  ##    ss       Same as above but always two digits. 0 is prepended.                               ``00:00:06 -> 06``
  ##    t        ``A`` when time is in the AM. ``P`` when time is in the PM.
  ##    tt       Same as above, but ``AM`` and ``PM`` instead of ``A`` and ``P`` respectively.
  ##    y(yyyy)  This displays the year to different digits. You most likely only want 2 or 4 'y's
  ##    yy       Displays the year to two digits.                                                   ``2012 -> 12``
  ##    yyyy     Displays the year to four digits.                                                  ``2012 -> 2012``
  ##    z        Displays the timezone offset from UTC.                                             ``GMT+7 -> +7``, ``GMT-5 -> -5``
  ##    zz       Same as above but with leading 0.                                                  ``GMT+7 -> +07``, ``GMT-5 -> -05``
  ##    zzz      Same as above but with ``:mm`` where *mm* represents minutes.                      ``GMT+7 -> +07:00``, ``GMT-5 -> -05:00``
  ## ==========  =================================================================================  ================================================
  ##
  ## Other strings can be inserted by putting them in ``''``. For example
  ## ``hh'->'mm`` will give ``01->56``.  The following characters can be
  ## inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]``
  ## ``,``. However you don't need to necessarily separate format specifiers, a
  ## unambiguous format string like ``yyyyMMddhhmmss`` is valid too.

  result = ""
  var i = 0
  var currentF = ""
  while true:
    case f[i]
    of ' ', '-', '/', ':', '\'', '\0', '(', ')', '[', ']', ',':
      formatToken(dt, currentF, result)

      currentF = ""
      if f[i] == '\0': break

      if f[i] == '\'':
        inc(i) # Skip '
        while f[i] != '\'' and f.len-1 > i:
          result.add(f[i])
          inc(i)
      else: result.add(f[i])

    else:
      # Check if the letter being added matches previous accumulated buffer.
      if currentF.len < 1 or currentF[high(currentF)] == f[i]:
        currentF.add(f[i])
      else:
        formatToken(dt, currentF, result)
        dec(i) # Move position back to re-process the character separately.
        currentF = ""

    inc(i)

proc `$`*(dt: DateTime): string {.tags: [], raises: [], benign.} =
  ## Converts a `DateTime` object to a string representation.
  ## It uses the format ``yyyy-MM-dd'T'HH-mm-sszzz``.
  try:
    result = format(dt, "yyyy-MM-dd'T'HH:mm:sszzz") # todo: optimize this
  except ValueError: assert false # cannot happen because format string is valid

proc `$`*(time: Time): string {.tags: [], raises: [], benign.} =
  ## converts a `Time` value to a string representation. It will use the local
  ## time zone and use the format ``yyyy-MM-dd'T'HH-mm-sszzz``.
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
    of "jan": dt.month =  mJan
    of "feb": dt.month =  mFeb
    of "mar": dt.month =  mMar
    of "apr": dt.month =  mApr
    of "may": dt.month =  mMay
    of "jun": dt.month =  mJun
    of "jul": dt.month =  mJul
    of "aug": dt.month =  mAug
    of "sep": dt.month =  mSep
    of "oct": dt.month =  mOct
    of "nov": dt.month =  mNov
    of "dec": dt.month =  mDec
    else:
      raise newException(ValueError,
        "Couldn't parse month (MMM), got: " & value)
    j += 3
  of "MMMM":
    if value.len >= j+7 and value[j..j+6].cmpIgnoreCase("january") == 0:
      dt.month =  mJan
      j += 7
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("february") == 0:
      dt.month =  mFeb
      j += 8
    elif value.len >= j+5 and value[j..j+4].cmpIgnoreCase("march") == 0:
      dt.month =  mMar
      j += 5
    elif value.len >= j+5 and value[j..j+4].cmpIgnoreCase("april") == 0:
      dt.month =  mApr
      j += 5
    elif value.len >= j+3 and value[j..j+2].cmpIgnoreCase("may") == 0:
      dt.month =  mMay
      j += 3
    elif value.len >= j+4 and value[j..j+3].cmpIgnoreCase("june") == 0:
      dt.month =  mJun
      j += 4
    elif value.len >= j+4 and value[j..j+3].cmpIgnoreCase("july") == 0:
      dt.month =  mJul
      j += 4
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("august") == 0:
      dt.month =  mAug
      j += 6
    elif value.len >= j+9 and value[j..j+8].cmpIgnoreCase("september") == 0:
      dt.month =  mSep
      j += 9
    elif value.len >= j+7 and value[j..j+6].cmpIgnoreCase("october") == 0:
      dt.month =  mOct
      j += 7
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("november") == 0:
      dt.month =  mNov
      j += 8
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("december") == 0:
      dt.month =  mDec
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
    if value[j] == 'P' and dt.hour > 0 and dt.hour < 12:
      dt.hour += 12
    j += 1
  of "tt":
    if value[j..j+1] == "PM" and dt.hour > 0 and dt.hour < 12:
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
    if value[j] == '+':
      dt.utcOffset = 0 - parseInt($value[j+1]) * secondsInHour
    elif value[j] == '-':
      dt.utcOffset = parseInt($value[j+1]) * secondsInHour
    elif value[j] == 'Z':
      dt.utcOffset = 0
      j += 1
      return
    else:
      raise newException(ValueError,
        "Couldn't parse timezone offset (z), got: " & value[j])
    j += 2
  of "zz":
    dt.isDst = false
    if value[j] == '+':
      dt.utcOffset = 0 - value[j+1..j+2].parseInt() * secondsInHour
    elif value[j] == '-':
      dt.utcOffset = value[j+1..j+2].parseInt() * secondsInHour
    elif value[j] == 'Z':
      dt.utcOffset = 0
      j += 1
      return
    else:
      raise newException(ValueError,
        "Couldn't parse timezone offset (zz), got: " & value[j])
    j += 3
  of "zzz":
    dt.isDst = false
    var factor = 0
    if value[j] == '+': factor = -1
    elif value[j] == '-': factor = 1
    elif value[j] == 'Z':
      dt.utcOffset = 0
      j += 1
      return
    else:
      raise newException(ValueError,
        "Couldn't parse timezone offset (zzz), got: " & value[j])
    dt.utcOffset = factor * value[j+1..j+2].parseInt() * secondsInHour
    j += 4
    dt.utcOffset += factor * value[j..j+1].parseInt() * 60
    j += 2
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
  ## ==========  =================================================================================  ================================================
  ## Specifier   Description                                                                        Example
  ## ==========  =================================================================================  ================================================
  ##    d        Numeric value of the day of the month, it will be one or two digits long.          ``1/04/2012 -> 1``, ``21/04/2012 -> 21``
  ##    dd       Same as above, but always two digits.                                              ``1/04/2012 -> 01``, ``21/04/2012 -> 21``
  ##    ddd      Three letter string which indicates the day of the week.                           ``Saturday -> Sat``, ``Monday -> Mon``
  ##    dddd     Full string for the day of the week.                                               ``Saturday -> Saturday``, ``Monday -> Monday``
  ##    h        The hours in one digit if possible. Ranging from 0-12.                             ``5pm -> 5``, ``2am -> 2``
  ##    hh       The hours in two digits always. If the hour is one digit 0 is prepended.           ``5pm -> 05``, ``11am -> 11``
  ##    H        The hours in one digit if possible, randing from 0-24.                             ``5pm -> 17``, ``2am -> 2``
  ##    HH       The hours in two digits always. 0 is prepended if the hour is one digit.           ``5pm -> 17``, ``2am -> 02``
  ##    m        The minutes in 1 digit if possible.                                                ``5:30 -> 30``, ``2:01 -> 1``
  ##    mm       Same as above but always 2 digits, 0 is prepended if the minute is one digit.      ``5:30 -> 30``, ``2:01 -> 01``
  ##    M        The month in one digit if possible.                                                ``September -> 9``, ``December -> 12``
  ##    MM       The month in two digits always. 0 is prepended.                                    ``September -> 09``, ``December -> 12``
  ##    MMM      Abbreviated three-letter form of the month.                                        ``September -> Sep``, ``December -> Dec``
  ##    MMMM     Full month string, properly capitalized.                                           ``September -> September``
  ##    s        Seconds as one digit if possible.                                                  ``00:00:06 -> 6``
  ##    ss       Same as above but always two digits. 0 is prepended.                               ``00:00:06 -> 06``
  ##    t        ``A`` when time is in the AM. ``P`` when time is in the PM.
  ##    tt       Same as above, but ``AM`` and ``PM`` instead of ``A`` and ``P`` respectively.
  ##    yy       Displays the year to two digits.                                                   ``2012 -> 12``
  ##    yyyy     Displays the year to four digits.                                                  ``2012 -> 2012``
  ##    z        Displays the timezone offset from UTC. ``Z`` is parsed as ``+0``                   ``GMT+7 -> +7``, ``GMT-5 -> -5``
  ##    zz       Same as above but with leading 0.                                                  ``GMT+7 -> +07``, ``GMT-5 -> -05``
  ##    zzz      Same as above but with ``:mm`` where *mm* represents minutes.                      ``GMT+7 -> +07:00``, ``GMT-5 -> -05:00``
  ## ==========  =================================================================================  ================================================
  ##
  ## Other strings can be inserted by putting them in ``''``. For example
  ## ``hh'->'mm`` will give ``01->56``.  The following characters can be
  ## inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]``
  ## ``,``. However you don't need to necessarily separate format specifiers, a
  ## unambiguous format string like ``yyyyMMddhhmmss`` is valid too.
  var i = 0 # pointer for format string
  var j = 0 # pointer for value string
  var token = ""
  # Assumes current day of month, month and year, but time is reset to 00:00:00. Weekday will be reset after parsing.
  var dt = now()
  dt.hour = 0
  dt.minute = 0
  dt.second = 0
  dt.isDst = true # using this is flag for checking whether a timezone has \
      # been read (because DST is always false when a tz is parsed)
  while true:
    case layout[i]
    of ' ', '-', '/', ':', '\'', '\0', '(', ')', '[', ']', ',':
      if token.len > 0:
        parseToken(dt, token, value, j)
      # Reset token
      token = ""
      # Break if at end of line
      if layout[i] == '\0': break
      # Skip separator and everything between single quotes
      # These are literals in both the layout and the value string
      if layout[i] == '\'':
        inc(i)
        while layout[i] != '\'' and layout.len-1 > i:
          inc(i)
          inc(j)
        inc(i)
      else:
        inc(i)
        inc(j)
    else:
      # Check if the letter being added matches previous accumulated buffer.
      if token.len < 1 or token[high(token)] == layout[i]:
        token.add(layout[i])
        inc(i)
      else:
        parseToken(dt, token, value, j)
        token = ""

  if dt.isDst:
    # No timezone parsed - assume timezone is `zone`
    result = initDateTime(zone.zoneInfoFromTz(dt.toAdjTime), zone)
  else:
    # Otherwise convert to `zone`
    result = dt.toTime.inZone(zone)

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
  ##
  ## .. code-block:: nim
  ##     let a = fromSeconds(1_000_000_000)
  ##     let b = fromSeconds(1_500_000_000)
  ##     echo a, " ", b  # real dates
  ##     echo a.toTimeInterval  # meaningless value, don't use it by itself
  ##     echo b.toTimeInterval - a.toTimeInterval
  ##     # (milliseconds: 0, seconds: -40, minutes: -6, hours: 1, days: 5, months: -2, years: 16)
  # Milliseconds not available from Time
  var dt = time.local
  initInterval(0, dt.second, dt.minute, dt.hour, dt.monthday, dt.month.ord - 1, dt.year)

proc initDateTime*(monthday: MonthdayRange, month: Month, year: int,
                   hour: HourRange, minute: MinuteRange, second: SecondRange, zone: Timezone = local()): DateTime =
  ## Create a new ``DateTime`` in the specified timezone.
  assertValidDate monthday, month, year
  doAssert monthday <= getDaysInMonth(month, year), "Invalid date: " & $month & " " & $monthday & ", " & $year
  let dt = DateTime(
    monthday:  monthday,
    year:  year,
    month:  month,
    hour:  hour,
    minute:  minute,
    second:  second
  )
  result = initDateTime(zone.zoneInfoFromTz(dt.toAdjTime), zone)

when not defined(JS):
  proc epochTime*(): float {.rtl, extern: "nt$1", tags: [TimeEffect].}
    ## gets time after the UNIX epoch (1970) in seconds. It is a float
    ## because sub-second resolution is likely to be supported (depending
    ## on the hardware/OS).

  proc cpuTime*(): float {.rtl, extern: "nt$1", tags: [TimeEffect].}
    ## gets time spent that the CPU spent to run the current process in
    ## seconds. This may be more useful for benchmarking than ``epochTime``.
    ## However, it may measure the real time instead (depending on the OS).
    ## The value of the result has no meaning.
    ## To generate useful timing values, take the difference between
    ## the results of two ``cpuTime`` calls:
    ##
    ## .. code-block:: nim
    ##   var t0 = cpuTime()
    ##   doWork()
    ##   echo "CPU time [s] ", cpuTime() - t0

when defined(JS):
  proc getTime(): Time =
    (newDate().getTime() div 1000).Time

  proc epochTime*(): float {.tags: [TimeEffect].} =
    newDate().getTime() / 1000

else:
  type
    Clock {.importc: "clock_t".} = distinct int

  proc timec(timer: ptr CTime): CTime {.
    importc: "time", header: "<time.h>", tags: [].}

  proc getClock(): Clock {.importc: "clock", header: "<time.h>", tags: [TimeEffect].}

  var
    clocksPerSec {.importc: "CLOCKS_PER_SEC", nodecl.}: int

  proc getTime(): Time =
    timec(nil).Time

  const
    epochDiff = 116444736000000000'i64
    rateDiff = 10000000'i64 # 100 nsecs

  proc unixTimeToWinTime*(time: CTime): int64 =
    ## converts a UNIX `Time` (``time_t``) to a Windows file time
    result = int64(time) * rateDiff + epochDiff

  proc winTimeToUnixTime*(time: int64): CTime =
    ## converts a Windows time to a UNIX `Time` (``time_t``)
    result = CTime((time - epochDiff) div rateDiff)

  when not defined(useNimRtl):
    proc epochTime(): float =
      when defined(posix):
        var a: Timeval
        posix_gettimeofday(a)
        result = toFloat(a.tv_sec) + toFloat(a.tv_usec)*0.00_0001
      elif defined(windows):
        var f: winlean.FILETIME
        getSystemTimeAsFileTime(f)
        var i64 = rdFileTime(f) - epochDiff
        var secs = i64 div rateDiff
        var subsecs = i64 mod rateDiff
        result = toFloat(int(secs)) + toFloat(int(subsecs)) * 0.0000001
      else:
        {.error: "unknown OS".}

    proc cpuTime(): float =
      result = toFloat(int(getClock())) / toFloat(clocksPerSec)

# Deprecated procs

proc fromSeconds*(since1970: float): Time {.tags: [], raises: [], benign, deprecated.} =
  ## Takes a float which contains the number of seconds since the unix epoch and
  ## returns a time object.
  ##
  ## **Deprecated since v0.18.0:** use ``fromUnix`` instead
  Time(since1970)

proc fromSeconds*(since1970: int64): Time {.tags: [], raises: [], benign, deprecated.} =
  ## Takes an int which contains the number of seconds since the unix epoch and
  ## returns a time object.
  ##
  ## **Deprecated since v0.18.0:** use ``fromUnix`` instead
  Time(since1970)

proc toSeconds*(time: Time): float {.tags: [], raises: [], benign, deprecated.} =
  ## Returns the time in seconds since the unix epoch.
  ##
  ## **Deprecated since v0.18.0:** use ``toUnix`` instead
  float(time)

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
    var a = timec(nil)
    let lt = localtime(addr(a))
    # BSD stores in `gmtoff` offset east of UTC in seconds,
    # but posix systems using west of UTC in seconds
    return -(lt.gmtoff)
  else:
    return timezone

proc timeInfoToTime*(dt: DateTime): Time {.tags: [], benign, deprecated.} =
  ## Converts a broken-down time structure to calendar time representation.
  ##
  ## **Warning:** This procedure is deprecated since version 0.14.0.
  ## Use ``toTime`` instead.
  dt.toTime

when defined(JS):
  var startMilsecs = getTime()
  proc getStartMilsecs*(): int {.deprecated, tags: [TimeEffect], benign.} =
    ## get the milliseconds from the start of the program. **Deprecated since
    ## version 0.8.10.** Use ``epochTime`` or ``cpuTime`` instead.
    when defined(JS):
      ## get the milliseconds from the start of the program
      return int(getTime() - startMilsecs)
else:
  proc getStartMilsecs*(): int {.deprecated, tags: [TimeEffect], benign.} =
    when defined(macosx):
      result = toInt(toFloat(int(getClock())) / (toFloat(clocksPerSec) / 1000.0))
    else:
      result = int(getClock()) div (clocksPerSec div 1000)

proc miliseconds*(t: TimeInterval): int {.deprecated.} =
  t.milliseconds

proc timeToTimeInterval*(t: Time): TimeInterval {.deprecated.} =
  ## Converts a Time to a TimeInterval.
  ##
  ## **Warning:** This procedure is deprecated since version 0.14.0.
  ## Use ``toTimeInterval`` instead.
  # Milliseconds not available from Time
  t.toTimeInterval()

proc timeToTimeInfo*(t: Time): DateTime {.deprecated.} =
  ## Converts a Time to DateTime.
  ##
  ## **Warning:** This procedure is deprecated since version 0.14.0.
  ## Use ``inZone`` instead.
  const epochStartYear = 1970

  let
    secs = t.toSeconds().int
    daysSinceEpoch = secs div secondsInDay
    (yearsSinceEpoch, daysRemaining) = countYearsAndDays(daysSinceEpoch)
    daySeconds = secs mod secondsInDay

    y = yearsSinceEpoch + epochStartYear

  var
    mon = mJan
    days = daysRemaining
    daysInMonth = getDaysInMonth(mon, y)

  # calculate month and day remainder
  while days > daysInMonth and mon <= mDec:
    days -= daysInMonth
    mon.inc
    daysInMonth = getDaysInMonth(mon, y)

  let
    yd = daysRemaining
    m = mon  # month is zero indexed enum
    md = days
    # NB: month is zero indexed but dayOfWeek expects 1 indexed.
    wd = getDayOfWeek(days, mon, y).Weekday
    h = daySeconds div secondsInHour + 1
    mi = (daySeconds mod secondsInHour) div secondsInMin
    s = daySeconds mod secondsInMin
  result = DateTime(year: y, yearday: yd, month: m, monthday: md, weekday: wd, hour: h, minute: mi, second: s)

proc getDayOfWeek*(day, month, year: int): WeekDay  {.tags: [], raises: [], benign, deprecated.} =
  getDayOfWeek(day, month.Month, year)

proc getDayOfWeekJulian*(day, month, year: int): WeekDay {.deprecated.} =
  ## Returns the day of the week enum from day, month and year,
  ## according to the Julian calendar.
  # Day & month start from one.
  let
    a = (14 - month) div 12
    y = year - a
    m = month + (12*a) - 2
    d = (5 + day + y + (y div 4) + (31*m) div 12) mod 7
  result = d.WeekDay
