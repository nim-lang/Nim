#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time.
## This module is available for the `JavaScript target
## <backends.html#the-javascript-target>`_.

{.push debugger:off.} # the user does not want to trace a part
                      # of the standard library!

import
  strutils, parseutils

include "system/inclrtl"

type
  Month* = enum ## represents a month
    mJan, mFeb, mMar, mApr, mMay, mJun, mJul, mAug, mSep, mOct, mNov, mDec
  WeekDay* = enum ## represents a weekday
    dMon, dTue, dWed, dThu, dFri, dSat, dSun

when not defined(JS):
  var
    timezone {.importc, header: "<time.h>".}: int
    tzname {.importc, header: "<time.h>" .}: array[0..1, cstring]

when defined(posix) and not defined(JS):
  type
    TimeImpl {.importc: "time_t", header: "<time.h>".} = int
    Time* = distinct TimeImpl ## distinct type that represents a time
                              ## measured as number of seconds since the epoch

    Timeval {.importc: "struct timeval",
              header: "<sys/select.h>".} = object ## struct timeval
      tv_sec: int  ## Seconds.
      tv_usec: int ## Microseconds.

  # we cannot import posix.nim here, because posix.nim depends on times.nim.
  # Ok, we could, but I don't want circular dependencies.
  # And gettimeofday() is not defined in the posix module anyway. Sigh.

  proc posix_gettimeofday(tp: var Timeval, unused: pointer = nil) {.
    importc: "gettimeofday", header: "<sys/time.h>".}

  # we also need tzset() to make sure that tzname is initialized
  proc tzset() {.importc, header: "<time.h>".}
  # calling tzset() implicitly to initialize tzname data.
  tzset()

elif defined(windows):
  import winlean

  when defined(vcc):
    # newest version of Visual C++ defines time_t to be of 64 bits
    type TimeImpl {.importc: "time_t", header: "<time.h>".} = int64
  else:
    type TimeImpl {.importc: "time_t", header: "<time.h>".} = int32

  type
    Time* = distinct TimeImpl

elif defined(JS):
  type
    Time* {.importc.} = object
      getDay: proc (): int {.tags: [], raises: [], benign.}
      getFullYear: proc (): int {.tags: [], raises: [], benign.}
      getHours: proc (): int {.tags: [], raises: [], benign.}
      getMilliseconds: proc (): int {.tags: [], raises: [], benign.}
      getMinutes: proc (): int {.tags: [], raises: [], benign.}
      getMonth: proc (): int {.tags: [], raises: [], benign.}
      getSeconds: proc (): int {.tags: [], raises: [], benign.}
      getTime: proc (): int {.tags: [], raises: [], benign.}
      getTimezoneOffset: proc (): int {.tags: [], raises: [], benign.}
      getDate: proc (): int {.tags: [], raises: [], benign.}
      getUTCDate: proc (): int {.tags: [], raises: [], benign.}
      getUTCFullYear: proc (): int {.tags: [], raises: [], benign.}
      getUTCHours: proc (): int {.tags: [], raises: [], benign.}
      getUTCMilliseconds: proc (): int {.tags: [], raises: [], benign.}
      getUTCMinutes: proc (): int {.tags: [], raises: [], benign.}
      getUTCMonth: proc (): int {.tags: [], raises: [], benign.}
      getUTCSeconds: proc (): int {.tags: [], raises: [], benign.}
      getUTCDay: proc (): int {.tags: [], raises: [], benign.}
      getYear: proc (): int {.tags: [], raises: [], benign.}
      parse: proc (s: cstring): Time {.tags: [], raises: [], benign.}
      setDate: proc (x: int) {.tags: [], raises: [], benign.}
      setFullYear: proc (x: int) {.tags: [], raises: [], benign.}
      setHours: proc (x: int) {.tags: [], raises: [], benign.}
      setMilliseconds: proc (x: int) {.tags: [], raises: [], benign.}
      setMinutes: proc (x: int) {.tags: [], raises: [], benign.}
      setMonth: proc (x: int) {.tags: [], raises: [], benign.}
      setSeconds: proc (x: int) {.tags: [], raises: [], benign.}
      setTime: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCDate: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCFullYear: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCHours: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCMilliseconds: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCMinutes: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCMonth: proc (x: int) {.tags: [], raises: [], benign.}
      setUTCSeconds: proc (x: int) {.tags: [], raises: [], benign.}
      setYear: proc (x: int) {.tags: [], raises: [], benign.}
      toGMTString: proc (): cstring {.tags: [], raises: [], benign.}
      toLocaleString: proc (): cstring {.tags: [], raises: [], benign.}

type
  TimeInfo* = object of RootObj ## represents a time in different parts
    second*: range[0..61]     ## The number of seconds after the minute,
                              ## normally in the range 0 to 59, but can
                              ## be up to 61 to allow for leap seconds.
    minute*: range[0..59]     ## The number of minutes after the hour,
                              ## in the range 0 to 59.
    hour*: range[0..23]       ## The number of hours past midnight,
                              ## in the range 0 to 23.
    monthday*: range[1..31]   ## The day of the month, in the range 1 to 31.
    month*: Month             ## The current month.
    year*: range[-10_000..10_000] ## The current year.
    weekday*: WeekDay         ## The current day of the week.
    yearday*: range[0..365]   ## The number of days since January 1,
                              ## in the range 0 to 365.
                              ## Always 0 if the target is JS.
    isDST*: bool              ## Determines whether DST is in effect. Always
                              ## ``False`` if time is UTC.
    tzname*: string           ## The timezone this time is in. E.g. GMT
    timezone*: int            ## The offset of the (non-DST) timezone in seconds
                              ## west of UTC.

  ## I make some assumptions about the data in here. Either
  ## everything should be positive or everything negative. Zero is
  ## fine too. Mixed signs will lead to unexpected results.
  TimeInterval* = object ## a time interval
    miliseconds*: int ## The number of miliseconds
    seconds*: int     ## The number of seconds
    minutes*: int     ## The number of minutes
    hours*: int       ## The number of hours
    days*: int        ## The number of days
    months*: int      ## The number of months
    years*: int       ## The number of years

{.deprecated: [TMonth: Month, TWeekDay: WeekDay, TTime: Time,
    TTimeInterval: TimeInterval, TTimeInfo: TimeInfo].}

proc getTime*(): Time {.tags: [TimeEffect], benign.}
  ## gets the current calendar time as a UNIX epoch value (number of seconds
  ## elapsed since 1970) with integer precission. Use epochTime for higher
  ## resolution.
proc getLocalTime*(t: Time): TimeInfo {.tags: [TimeEffect], raises: [], benign.}
  ## converts the calendar time `t` to broken-time representation,
  ## expressed relative to the user's specified time zone.
proc getGMTime*(t: Time): TimeInfo {.tags: [TimeEffect], raises: [], benign.}
  ## converts the calendar time `t` to broken-down time representation,
  ## expressed in Coordinated Universal Time (UTC).

proc timeInfoToTime*(timeInfo: TimeInfo): Time {.tags: [], benign.}
  ## converts a broken-down time structure to
  ## calendar time representation. The function ignores the specified
  ## contents of the structure members `weekday` and `yearday` and recomputes
  ## them from the other information in the broken-down time structure.

proc fromSeconds*(since1970: float): Time {.tags: [], raises: [], benign.}
  ## Takes a float which contains the number of seconds since the unix epoch and
  ## returns a time object.

proc fromSeconds*(since1970: int64): Time {.tags: [], raises: [], benign.} =
  ## Takes an int which contains the number of seconds since the unix epoch and
  ## returns a time object.
  fromSeconds(float(since1970))

proc toSeconds*(time: Time): float {.tags: [], raises: [], benign.}
  ## Returns the time in seconds since the unix epoch.

proc `$` *(timeInfo: TimeInfo): string {.tags: [], raises: [], benign.}
  ## converts a `TimeInfo` object to a string representation.
proc `$` *(time: Time): string {.tags: [], raises: [], benign.}
  ## converts a calendar time to a string representation.

proc `-`*(a, b: Time): int64 {.
  rtl, extern: "ntDiffTime", tags: [], raises: [], benign.}
  ## computes the difference of two calendar times. Result is in seconds.

proc `<`*(a, b: Time): bool {.
  rtl, extern: "ntLtTime", tags: [], raises: [].} =
  ## returns true iff ``a < b``, that is iff a happened before b.
  result = a - b < 0

proc `<=` * (a, b: Time): bool {.
  rtl, extern: "ntLeTime", tags: [], raises: [].}=
  ## returns true iff ``a <= b``.
  result = a - b <= 0

proc `==`*(a, b: Time): bool {.
  rtl, extern: "ntEqTime", tags: [], raises: [].} =
  ## returns true if ``a == b``, that is if both times represent the same value
  result = a - b == 0

when not defined(JS):
  proc getTzname*(): tuple[nonDST, DST: string] {.tags: [TimeEffect], raises: [],
    benign.}
    ## returns the local timezone; ``nonDST`` is the name of the local non-DST
    ## timezone, ``DST`` is the name of the local DST timezone.

proc getTimezone*(): int {.tags: [TimeEffect], raises: [], benign.}
  ## returns the offset of the local (non-DST) timezone in seconds west of UTC.

proc getStartMilsecs*(): int {.deprecated, tags: [TimeEffect], benign.}
  ## get the miliseconds from the start of the program. **Deprecated since
  ## version 0.8.10.** Use ``epochTime`` or ``cpuTime`` instead.

proc initInterval*(miliseconds, seconds, minutes, hours, days, months,
                   years: int = 0): TimeInterval =
  ## creates a new ``TimeInterval``.
  result.miliseconds = miliseconds
  result.seconds = seconds
  result.minutes = minutes
  result.hours = hours
  result.days = days
  result.months = months
  result.years = years

proc isLeapYear*(year: int): bool =
  ## returns true if ``year`` is a leap year

  if year mod 400 == 0:
    return true
  elif year mod 100 == 0:
    return false
  elif year mod 4 == 0:
    return true
  else:
    return false

proc getDaysInMonth*(month: Month, year: int): int =
  ## gets the amount of days in a ``month`` of a ``year``

  # http://www.dispersiondesign.com/articles/time/number_of_days_in_a_month
  case month
  of mFeb: result = if isLeapYear(year): 29 else: 28
  of mApr, mJun, mSep, mNov: result = 30
  else: result = 31

proc toSeconds(a: TimeInfo, interval: TimeInterval): float =
  ## Calculates how many seconds the interval is worth by adding up
  ## all the fields

  var anew = a
  var newinterv = interval
  result = 0

  newinterv.months += interval.years * 12
  var curMonth = anew.month
  for mth in 1 .. newinterv.months:
    result += float(getDaysInMonth(curMonth, anew.year) * 24 * 60 * 60)
    if curMonth == mDec:
      curMonth = mJan
      anew.year.inc()
    else:
      curMonth.inc()
  result += float(newinterv.days * 24 * 60 * 60)
  result += float(newinterv.hours * 60 * 60)
  result += float(newinterv.minutes * 60)
  result += float(newinterv.seconds)
  result += newinterv.miliseconds / 1000

proc `+`*(a: TimeInfo, interval: TimeInterval): TimeInfo =
  ## adds ``interval`` time.
  ##
  ## **Note:** This has been only briefly tested and it may not be
  ## very accurate.
  let t = toSeconds(timeInfoToTime(a))
  let secs = toSeconds(a, interval)
  if a.tzname == "UTC":
    result = getGMTime(fromSeconds(t + secs))
  else:
    result = getLocalTime(fromSeconds(t + secs))

proc `-`*(a: TimeInfo, interval: TimeInterval): TimeInfo =
  ## subtracts ``interval`` time.
  ##
  ## **Note:** This has been only briefly tested, it is inaccurate especially
  ## when you subtract so much that you reach the Julian calendar.
  let t = toSeconds(timeInfoToTime(a))
  let secs = toSeconds(a, interval)
  if a.tzname == "UTC":
    result = getGMTime(fromSeconds(t - secs))
  else:
    result = getLocalTime(fromSeconds(t - secs))

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

when not defined(JS):
  # C wrapper:
  type
    StructTM {.importc: "struct tm", final.} = object
      second {.importc: "tm_sec".},
        minute {.importc: "tm_min".},
        hour {.importc: "tm_hour".},
        monthday {.importc: "tm_mday".},
        month {.importc: "tm_mon".},
        year {.importc: "tm_year".},
        weekday {.importc: "tm_wday".},
        yearday {.importc: "tm_yday".},
        isdst {.importc: "tm_isdst".}: cint

    TimeInfoPtr = ptr StructTM
    Clock {.importc: "clock_t".} = distinct int

  proc localtime(timer: ptr Time): TimeInfoPtr {.
    importc: "localtime", header: "<time.h>", tags: [].}
  proc gmtime(timer: ptr Time): TimeInfoPtr {.
    importc: "gmtime", header: "<time.h>", tags: [].}
  proc timec(timer: ptr Time): Time {.
    importc: "time", header: "<time.h>", tags: [].}
  proc mktime(t: StructTM): Time {.
    importc: "mktime", header: "<time.h>", tags: [].}
  proc asctime(tblock: StructTM): cstring {.
    importc: "asctime", header: "<time.h>", tags: [].}
  proc ctime(time: ptr Time): cstring {.
    importc: "ctime", header: "<time.h>", tags: [].}
  #  strftime(s: CString, maxsize: int, fmt: CString, t: tm): int {.
  #    importc: "strftime", header: "<time.h>".}
  proc getClock(): Clock {.importc: "clock", header: "<time.h>", tags: [TimeEffect].}
  proc difftime(a, b: Time): float {.importc: "difftime", header: "<time.h>",
    tags: [].}

  var
    clocksPerSec {.importc: "CLOCKS_PER_SEC", nodecl.}: int

  # our own procs on top of that:
  proc tmToTimeInfo(tm: StructTM, local: bool): TimeInfo =
    const
      weekDays: array [0..6, WeekDay] = [
        dSun, dMon, dTue, dWed, dThu, dFri, dSat]
    TimeInfo(second: int(tm.second),
      minute: int(tm.minute),
      hour: int(tm.hour),
      monthday: int(tm.monthday),
      month: Month(tm.month),
      year: tm.year + 1900'i32,
      weekday: weekDays[int(tm.weekday)],
      yearday: int(tm.yearday),
      isDST: tm.isdst > 0,
      tzname: if local:
          if tm.isdst > 0:
            getTzname().DST
          else:
            getTzname().nonDST
        else:
          "UTC",
      timezone: if local: getTimezone() else: 0
    )

  proc timeInfoToTM(t: TimeInfo): StructTM =
    const
      weekDays: array [WeekDay, int8] = [1'i8,2'i8,3'i8,4'i8,5'i8,6'i8,0'i8]
    result.second = t.second
    result.minute = t.minute
    result.hour = t.hour
    result.monthday = t.monthday
    result.month = ord(t.month)
    result.year = t.year - 1900
    result.weekday = weekDays[t.weekday]
    result.yearday = t.yearday
    result.isdst = if t.isDST: 1 else: 0

  when not defined(useNimRtl):
    proc `-` (a, b: Time): int64 =
      return toBiggestInt(difftime(a, b))

  proc getStartMilsecs(): int =
    #echo "clocks per sec: ", clocksPerSec, "clock: ", int(getClock())
    #return getClock() div (clocksPerSec div 1000)
    when defined(macosx):
      result = toInt(toFloat(int(getClock())) / (toFloat(clocksPerSec) / 1000.0))
    else:
      result = int(getClock()) div (clocksPerSec div 1000)
    when false:
      var a: Timeval
      posix_gettimeofday(a)
      result = a.tv_sec * 1000'i64 + a.tv_usec div 1000'i64
      #echo "result: ", result

  proc getTime(): Time = return timec(nil)
  proc getLocalTime(t: Time): TimeInfo =
    var a = t
    result = tmToTimeInfo(localtime(addr(a))[], true)
    # copying is needed anyway to provide reentrancity; thus
    # the conversion is not expensive

  proc getGMTime(t: Time): TimeInfo =
    var a = t
    result = tmToTimeInfo(gmtime(addr(a))[], false)
    # copying is needed anyway to provide reentrancity; thus
    # the conversion is not expensive

  proc timeInfoToTime(timeInfo: TimeInfo): Time =
    var cTimeInfo = timeInfo # for C++ we have to make a copy,
    # because the header of mktime is broken in my version of libc
    return mktime(timeInfoToTM(cTimeInfo))

  proc toStringTillNL(p: cstring): string =
    result = ""
    var i = 0
    while p[i] != '\0' and p[i] != '\10' and p[i] != '\13':
      add(result, p[i])
      inc(i)

  proc `$`(timeInfo: TimeInfo): string =
    # BUGFIX: asctime returns a newline at the end!
    var p = asctime(timeInfoToTM(timeInfo))
    result = toStringTillNL(p)

  proc `$`(time: Time): string =
    # BUGFIX: ctime returns a newline at the end!
    var a = time
    return toStringTillNL(ctime(addr(a)))

  const
    epochDiff = 116444736000000000'i64
    rateDiff = 10000000'i64 # 100 nsecs

  proc unixTimeToWinTime*(t: Time): int64 =
    ## converts a UNIX `Time` (``time_t``) to a Windows file time
    result = int64(t) * rateDiff + epochDiff

  proc winTimeToUnixTime*(t: int64): Time =
    ## converts a Windows time to a UNIX `Time` (``time_t``)
    result = Time((t - epochDiff) div rateDiff)

  proc getTzname(): tuple[nonDST, DST: string] =
    return ($tzname[0], $tzname[1])

  proc getTimezone(): int =
    return timezone

  proc fromSeconds(since1970: float): Time = Time(since1970)

  proc toSeconds(time: Time): float = float(time)

  when not defined(useNimRtl):
    proc epochTime(): float =
      when defined(posix):
        var a: Timeval
        posix_gettimeofday(a)
        result = toFloat(a.tv_sec) + toFloat(a.tv_usec)*0.00_0001
      elif defined(windows):
        var f: winlean.TFILETIME
        getSystemTimeAsFileTime(f)
        var i64 = rdFileTime(f) - epochDiff
        var secs = i64 div rateDiff
        var subsecs = i64 mod rateDiff
        result = toFloat(int(secs)) + toFloat(int(subsecs)) * 0.0000001
      else:
        {.error: "unknown OS".}

    proc cpuTime(): float =
      result = toFloat(int(getClock())) / toFloat(clocksPerSec)

elif defined(JS):
  proc newDate(): Time {.importc: "new Date".}
  proc internGetTime(): Time {.importc: "new Date", tags: [].}

  proc newDate(value: float): Time {.importc: "new Date".}
  proc newDate(value: string): Time {.importc: "new Date".}
  proc getTime(): Time =
    # Warning: This is something different in JS.
    return newDate()

  const
    weekDays: array [0..6, WeekDay] = [
      dSun, dMon, dTue, dWed, dThu, dFri, dSat]

  proc getLocalTime(t: Time): TimeInfo =
    result.second = t.getSeconds()
    result.minute = t.getMinutes()
    result.hour = t.getHours()
    result.monthday = t.getDate()
    result.month = Month(t.getMonth())
    result.year = t.getFullYear()
    result.weekday = weekDays[t.getDay()]
    result.yearday = 0

  proc getGMTime(t: Time): TimeInfo =
    result.second = t.getUTCSeconds()
    result.minute = t.getUTCMinutes()
    result.hour = t.getUTCHours()
    result.monthday = t.getUTCDate()
    result.month = Month(t.getUTCMonth())
    result.year = t.getUTCFullYear()
    result.weekday = weekDays[t.getUTCDay()]
    result.yearday = 0

  proc timeInfoToTime*(timeInfo: TimeInfo): Time =
    result = internGetTime()
    result.setSeconds(timeInfo.second)
    result.setMinutes(timeInfo.minute)
    result.setHours(timeInfo.hour)
    result.setMonth(ord(timeInfo.month))
    result.setFullYear(timeInfo.year)
    result.setDate(timeInfo.monthday)

  proc `$`(timeInfo: TimeInfo): string = return $(timeInfoToTime(timeInfo))
  proc `$`(time: Time): string = return $time.toLocaleString()

  proc `-` (a, b: Time): int64 =
    return a.getTime() - b.getTime()

  var
    startMilsecs = getTime()

  proc getStartMilsecs(): int =
    ## get the miliseconds from the start of the program
    return int(getTime() - startMilsecs)

  proc valueOf(time: Time): float {.importcpp: "getTime", tags:[]}

  proc fromSeconds(since1970: float): Time = result = newDate(since1970)

  proc toSeconds(time: Time): float = result = time.valueOf() / 1000

  proc getTimezone(): int = result = newDate().getTimezoneOffset()

proc getDateStr*(): string {.rtl, extern: "nt$1", tags: [TimeEffect].} =
  ## gets the current date as a string of the format ``YYYY-MM-DD``.
  var ti = getLocalTime(getTime())
  result = $ti.year & '-' & intToStr(ord(ti.month)+1, 2) &
    '-' & intToStr(ti.monthday, 2)

proc getClockStr*(): string {.rtl, extern: "nt$1", tags: [TimeEffect].} =
  ## gets the current clock time as a string of the format ``HH:MM:SS``.
  var ti = getLocalTime(getTime())
  result = intToStr(ti.hour, 2) & ':' & intToStr(ti.minute, 2) &
    ':' & intToStr(ti.second, 2)

proc `$`*(day: WeekDay): string =
  ## stingify operator for ``WeekDay``.
  const lookup: array[WeekDay, string] = ["Monday", "Tuesday", "Wednesday",
     "Thursday", "Friday", "Saturday", "Sunday"]
  return lookup[day]

proc `$`*(m: Month): string =
  ## stingify operator for ``Month``.
  const lookup: array[Month, string] = ["January", "February", "March",
      "April", "May", "June", "July", "August", "September", "October",
      "November", "December"]
  return lookup[m]

proc formatToken(info: TimeInfo, token: string, buf: var string) =
  ## Helper of the format proc to parse individual tokens.
  ##
  ## Pass the found token in the user input string, and the buffer where the
  ## final string is being built. This has to be a var value because certain
  ## formatting tokens require modifying the previous characters.
  case token
  of "d":
    buf.add($info.monthday)
  of "dd":
    if info.monthday < 10:
      buf.add("0")
    buf.add($info.monthday)
  of "ddd":
    buf.add(($info.weekday)[0 .. 2])
  of "dddd":
    buf.add($info.weekday)
  of "h":
    buf.add($(if info.hour > 12: info.hour - 12 else: info.hour))
  of "hh":
    let amerHour = if info.hour > 12: info.hour - 12 else: info.hour
    if amerHour < 10:
      buf.add('0')
    buf.add($amerHour)
  of "H":
    buf.add($info.hour)
  of "HH":
    if info.hour < 10:
      buf.add('0')
    buf.add($info.hour)
  of "m":
    buf.add($info.minute)
  of "mm":
    if info.minute < 10:
      buf.add('0')
    buf.add($info.minute)
  of "M":
    buf.add($(int(info.month)+1))
  of "MM":
    if info.month < mOct:
      buf.add('0')
    buf.add($(int(info.month)+1))
  of "MMM":
    buf.add(($info.month)[0..2])
  of "MMMM":
    buf.add($info.month)
  of "s":
    buf.add($info.second)
  of "ss":
    if info.second < 10:
      buf.add('0')
    buf.add($info.second)
  of "t":
    if info.hour >= 12:
      buf.add('P')
    else: buf.add('A')
  of "tt":
    if info.hour >= 12:
      buf.add("PM")
    else: buf.add("AM")
  of "y":
    var fr = ($info.year).len()-1
    if fr < 0: fr = 0
    buf.add(($info.year)[fr .. ($info.year).len()-1])
  of "yy":
    var fr = ($info.year).len()-2
    if fr < 0: fr = 0
    var fyear = ($info.year)[fr .. ($info.year).len()-1]
    if fyear.len != 2: fyear = repeat('0', 2-fyear.len()) & fyear
    buf.add(fyear)
  of "yyy":
    var fr = ($info.year).len()-3
    if fr < 0: fr = 0
    var fyear = ($info.year)[fr .. ($info.year).len()-1]
    if fyear.len != 3: fyear = repeat('0', 3-fyear.len()) & fyear
    buf.add(fyear)
  of "yyyy":
    var fr = ($info.year).len()-4
    if fr < 0: fr = 0
    var fyear = ($info.year)[fr .. ($info.year).len()-1]
    if fyear.len != 4: fyear = repeat('0', 4-fyear.len()) & fyear
    buf.add(fyear)
  of "yyyyy":
    var fr = ($info.year).len()-5
    if fr < 0: fr = 0
    var fyear = ($info.year)[fr .. ($info.year).len()-1]
    if fyear.len != 5: fyear = repeat('0', 5-fyear.len()) & fyear
    buf.add(fyear)
  of "z":
    let hrs = (info.timezone div 60) div 60
    buf.add($hrs)
  of "zz":
    let hrs = (info.timezone div 60) div 60

    buf.add($hrs)
    if hrs.abs < 10:
      var atIndex = buf.len-(($hrs).len-(if hrs < 0: 1 else: 0))
      buf.insert("0", atIndex)
  of "zzz":
    let hrs = (info.timezone div 60) div 60

    buf.add($hrs & ":00")
    if hrs.abs < 10:
      var atIndex = buf.len-(($hrs & ":00").len-(if hrs < 0: 1 else: 0))
      buf.insert("0", atIndex)
  of "ZZZ":
    buf.add(info.tzname)
  of "":
    discard
  else:
    raise newException(ValueError, "Invalid format string: " & token)


proc format*(info: TimeInfo, f: string): string =
  ## This function formats `info` as specified by `f`. The following format
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
  ##    zzz      Same as above but with ``:00``.                                                    ``GMT+7 -> +07:00``, ``GMT-5 -> -05:00``
  ##    ZZZ      Displays the name of the timezone.                                                 ``GMT -> GMT``, ``EST -> EST``
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
      formatToken(info, currentF, result)

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
        formatToken(info, currentF, result)
        dec(i) # Move position back to re-process the character separately.
        currentF = ""

    inc(i)

{.pop.}

proc parseToken(info: var TimeInfo; token, value: string; j: var int) =
  ## Helper of the parse proc to parse individual tokens.
  var sv: int
  case token
  of "d":
    var pd = parseInt(value[j..j+1], sv)
    info.monthday = sv
    j += pd
  of "dd":
    info.monthday = value[j..j+1].parseInt()
    j += 2
  of "ddd":
    case value[j..j+2].toLower():
    of "sun":
      info.weekday = dSun
    of "mon":
      info.weekday = dMon
    of "tue":
      info.weekday = dTue
    of "wed":
      info.weekday = dWed
    of "thu":
      info.weekday = dThu
    of "fri":
      info.weekday = dFri
    of "sat":
      info.weekday = dSat
    else:
      raise newException(ValueError, "invalid day of week ")
    j += 3
  of "dddd":
    if value.len >= j+6 and value[j..j+5].cmpIgnoreCase("sunday") == 0:
      info.weekday = dSun
      j += 6
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("monday") == 0:
      info.weekday = dMon
      j += 6
    elif value.len >= j+7 and value[j..j+6].cmpIgnoreCase("tuesday") == 0:
      info.weekday = dTue
      j += 7
    elif value.len >= j+9 and value[j..j+8].cmpIgnoreCase("wednesday") == 0:
      info.weekday = dWed
      j += 9
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("thursday") == 0:
      info.weekday = dThu
      j += 8
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("friday") == 0:
      info.weekday = dFri
      j += 6
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("saturday") == 0:
      info.weekday = dSat
      j += 8
    else:
      raise newException(ValueError, "invalid day of week ")
  of "h", "H":
    var pd = parseInt(value[j..j+1], sv)
    info.hour = sv
    j += pd
  of "hh", "HH":
    info.hour = value[j..j+1].parseInt()
    j += 2
  of "m":
    var pd = parseInt(value[j..j+1], sv)
    info.minute = sv
    j += pd
  of "mm":
    info.minute = value[j..j+1].parseInt()
    j += 2
  of "M":
    var pd = parseInt(value[j..j+1], sv)
    info.month = Month(sv-1)
    info.monthday = sv
    j += pd
  of "MM":
    var month = value[j..j+1].parseInt()
    j += 2
    info.month = Month(month-1)
  of "MMM":
    case value[j..j+2].toLower():
    of "jan":
      info.month =  mJan
    of "feb":
      info.month =  mFeb
    of "mar":
      info.month =  mMar
    of "apr":
      info.month =  mApr
    of "may":
      info.month =  mMay
    of "jun":
      info.month =  mJun
    of "jul":
      info.month =  mJul
    of "aug":
      info.month =  mAug
    of "sep":
      info.month =  mSep
    of "oct":
      info.month =  mOct
    of "nov":
      info.month =  mNov
    of "dec":
      info.month =  mDec
    else:
      raise newException(ValueError, "invalid month")
    j += 3
  of "MMMM":
    if value.len >= j+7 and value[j..j+6].cmpIgnoreCase("january") == 0:
      info.month =  mJan
      j += 7
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("february") == 0:
      info.month =  mFeb
      j += 8
    elif value.len >= j+5 and value[j..j+4].cmpIgnoreCase("march") == 0:
      info.month =  mMar
      j += 5
    elif value.len >= j+5 and value[j..j+4].cmpIgnoreCase("april") == 0:
      info.month =  mApr
      j += 5
    elif value.len >= j+3 and value[j..j+2].cmpIgnoreCase("may") == 0:
      info.month =  mMay
      j += 3
    elif value.len >= j+4 and value[j..j+3].cmpIgnoreCase("june") == 0:
      info.month =  mJun
      j += 4
    elif value.len >= j+4 and value[j..j+3].cmpIgnoreCase("july") == 0:
      info.month =  mJul
      j += 4
    elif value.len >= j+6 and value[j..j+5].cmpIgnoreCase("august") == 0:
      info.month =  mAug
      j += 6
    elif value.len >= j+9 and value[j..j+8].cmpIgnoreCase("september") == 0:
      info.month =  mSep
      j += 9
    elif value.len >= j+7 and value[j..j+6].cmpIgnoreCase("october") == 0:
      info.month =  mOct
      j += 7
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("november") == 0:
      info.month =  mNov
      j += 8
    elif value.len >= j+8 and value[j..j+7].cmpIgnoreCase("december") == 0:
      info.month =  mDec
      j += 8
    else:
      raise newException(ValueError, "invalid month")
  of "s":
    var pd = parseInt(value[j..j+1], sv)
    info.second = sv
    j += pd
  of "ss":
    info.second = value[j..j+1].parseInt()
    j += 2
  of "t":
    if value[j] == 'P' and info.hour > 0 and info.hour < 12:
      info.hour += 12
    j += 1
  of "tt":
    if value[j..j+1] == "PM" and info.hour > 0 and info.hour < 12:
      info.hour += 12
    j += 2
  of "yy":
    # Assumes current century
    var year = value[j..j+1].parseInt()
    var thisCen = getLocalTime(getTime()).year div 100
    info.year = thisCen*100 + year
    j += 2
  of "yyyy":
    info.year = value[j..j+3].parseInt()
    j += 4
  of "z":
    if value[j] == '+':
      info.timezone = parseInt($value[j+1])
    elif value[j] == '-':
      info.timezone = 0-parseInt($value[j+1])
    else:
      raise newException(ValueError, "Sign for timezone " & value[j])
    j += 2
  of "zz":
    if value[j] == '+':
      info.timezone = value[j+1..j+2].parseInt()
    elif value[j] == '-':
      info.timezone = 0-value[j+1..j+2].parseInt()
    else:
      raise newException(ValueError, "Sign for timezone " & value[j])
    j += 3
  of "zzz":
    if value[j] == '+':
      info.timezone = value[j+1..j+2].parseInt()
    elif value[j] == '-':
      info.timezone = 0-value[j+1..j+2].parseInt()
    else:
      raise newException(ValueError, "Sign for timezone " & value[j])
    j += 6
  of "ZZZ":
    info.tzname = value[j..j+2].toUpper()
    j += 3
  else:
    # Ignore the token and move forward in the value string by the same length
    j += token.len

proc parse*(value, layout: string): TimeInfo =
  ## This function parses a date/time string using the standard format identifiers (below)
  ## The function defaults information not provided in the format string from the running program (timezone, month, year, etc)
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
  ##    z        Displays the timezone offset from UTC.                                             ``GMT+7 -> +7``, ``GMT-5 -> -5``
  ##    zz       Same as above but with leading 0.                                                  ``GMT+7 -> +07``, ``GMT-5 -> -05``
  ##    zzz      Same as above but with ``:00``.                                                    ``GMT+7 -> +07:00``, ``GMT-5 -> -05:00``
  ##    ZZZ      Displays the name of the timezone.                                                 ``GMT -> GMT``, ``EST -> EST``
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
  var info = getLocalTime(getTime())
  info.hour = 0
  info.minute = 0
  info.second = 0
  while true:
    case layout[i]
    of ' ', '-', '/', ':', '\'', '\0', '(', ')', '[', ']', ',':
      if token.len > 0:
        parseToken(info, token, value, j)
      # Reset token
      token = ""
      # Break if at end of line
      if layout[i] == '\0': break
      # Skip separator and everything between single quotes
      # These are literals in both the layout and the value string
      if layout[i] == '\'':
        inc(i)
        inc(j)
        while layout[i] != '\'' and layout.len-1 > i:
          inc(i)
          inc(j)
      else:
        inc(i)
        inc(j)
    else:
      # Check if the letter being added matches previous accumulated buffer.
      if token.len < 1 or token[high(token)] == layout[i]:
        token.add(layout[i])
        inc(i)
      else:
        parseToken(info, token, value, j)
        token = ""
  # Reset weekday as it might not have been provided and the default may be wrong
  info.weekday = getLocalTime(timeInfoToTime(info)).weekday
  return info


when isMainModule:
  # $ date --date='@2147483647'
  # Tue 19 Jan 03:14:07 GMT 2038

  var t = getGMTime(fromSeconds(2147483647))
  echo t.format("ddd dd MMM hh:mm:ss ZZZ yyyy")
  echo t.format("ddd ddMMMhhmmssZZZyyyy")
  assert t.format("ddd dd MMM hh:mm:ss ZZZ yyyy") == "Tue 19 Jan 03:14:07 UTC 2038"
  assert t.format("ddd ddMMMhh:mm:ssZZZyyyy") == "Tue 19Jan03:14:07UTC2038"

  assert t.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
    " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
    "19 19 Tue Tuesday 3 03 3 03 14 14 1 01 Jan January 7 07 A AM 8 38 038 2038 02038 0 00 00:00 UTC"

  assert t.format("yyyyMMddhhmmss") == "20380119031407"

  var t2 = getGMTime(fromSeconds(160070789)) # Mon 27 Jan 16:06:29 GMT 1975
  assert t2.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
    " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
    "27 27 Mon Monday 4 04 16 16 6 06 1 01 Jan January 29 29 P PM 5 75 975 1975 01975 0 00 00:00 UTC"

  when not defined(JS) and sizeof(Time) == 8:
    var t3 = getGMTime(fromSeconds(889067643645)) # Fri  7 Jun 19:20:45 BST 30143
    assert t3.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
      " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
      "7 07 Fri Friday 6 06 18 18 20 20 6 06 Jun June 45 45 P PM 3 43 143 0143 30143 0 00 00:00 UTC"
    assert t3.format(":,[]()-/") == ":,[]()-/"

  var t4 = getGMTime(fromSeconds(876124714)) # Mon  6 Oct 08:58:34 BST 1997
  assert t4.format("M MM MMM MMMM") == "10 10 Oct October"

  # Interval tests
  assert((t4 - initInterval(years = 2)).format("yyyy") == "1995")
  assert((t4 - initInterval(years = 7, minutes = 34, seconds = 24)).format("yyyy mm ss") == "1990 24 10")

  var s = "Tuesday at 09:04am on Dec 15, 2015"
  var f = "dddd at hh:mmtt on MMM d, yyyy"
  assert($s.parse(f) == "Tue Dec 15 09:04:00 2015")
  # ANSIC       = "Mon Jan _2 15:04:05 2006"
  s = "Mon Jan 2 15:04:05 2006"
  f = "ddd MMM d HH:mm:ss yyyy"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # UnixDate    = "Mon Jan _2 15:04:05 MST 2006"
  s = "Mon Jan 2 15:04:05 MST 2006"
  f = "ddd MMM d HH:mm:ss ZZZ yyyy"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # RubyDate    = "Mon Jan 02 15:04:05 -0700 2006"
  s = "Mon Jan 02 15:04:05 -07:00 2006"
  f = "ddd MMM dd HH:mm:ss zzz yyyy"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # RFC822      = "02 Jan 06 15:04 MST"
  s = "02 Jan 06 15:04 MST"
  f = "dd MMM yy HH:mm ZZZ"
  assert($s.parse(f) == "Mon Jan  2 15:04:00 2006")
  # RFC822Z     = "02 Jan 06 15:04 -0700" # RFC822 with numeric zone
  s = "02 Jan 06 15:04 -07:00"
  f = "dd MMM yy HH:mm zzz"
  assert($s.parse(f) == "Mon Jan  2 15:04:00 2006")
  # RFC850      = "Monday, 02-Jan-06 15:04:05 MST"
  s = "Monday, 02-Jan-06 15:04:05 MST"
  f = "dddd, dd-MMM-yy HH:mm:ss ZZZ"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # RFC1123     = "Mon, 02 Jan 2006 15:04:05 MST"
  s = "Mon, 02 Jan 2006 15:04:05 MST"
  f = "ddd, dd MMM yyyy HH:mm:ss ZZZ"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # RFC1123Z    = "Mon, 02 Jan 2006 15:04:05 -0700" # RFC1123 with numeric zone
  s = "Mon, 02 Jan 2006 15:04:05 -07:00"
  f = "ddd, dd MMM yyyy HH:mm:ss zzz"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # RFC3339     = "2006-01-02T15:04:05Z07:00"
  s = "2006-01-02T15:04:05Z-07:00"
  f = "yyyy-MM-ddTHH:mm:ssZzzz"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # RFC3339Nano = "2006-01-02T15:04:05.999999999Z07:00"
  s = "2006-01-02T15:04:05.999999999Z-07:00"
  f = "yyyy-MM-ddTHH:mm:ss.999999999Zzzz"
  assert($s.parse(f) == "Mon Jan  2 15:04:05 2006")
  # Kitchen     = "3:04PM"
  s = "3:04PM"
  f = "h:mmtt"
  echo "Kitchen: " & $s.parse(f)
