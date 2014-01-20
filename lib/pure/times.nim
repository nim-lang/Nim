#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time.
## This module is available for the JavaScript target.

{.push debugger:off.} # the user does not want to trace a part
                      # of the standard library!

import
  strutils

include "system/inclrtl"

type
  TMonth* = enum ## represents a month
    mJan, mFeb, mMar, mApr, mMay, mJun, mJul, mAug, mSep, mOct, mNov, mDec
  TWeekDay* = enum ## represents a weekday
    dMon, dTue, dWed, dThu, dFri, dSat, dSun

var
  timezone {.importc, header: "<time.h>".}: int
  tzname {.importc, header: "<time.h>" .}: array[0..1, cstring]

when defined(posix) and not defined(JS):
  type
    TTimeImpl {.importc: "time_t", header: "<sys/time.h>".} = int
    TTime* = distinct TTimeImpl ## distinct type that represents a time
                                ## measured as number of seconds since the epoch
    
    Ttimeval {.importc: "struct timeval", header: "<sys/select.h>", 
               final, pure.} = object ## struct timeval
      tv_sec: int  ## Seconds. 
      tv_usec: int ## Microseconds. 
      
  # we cannot import posix.nim here, because posix.nim depends on times.nim.
  # Ok, we could, but I don't want circular dependencies. 
  # And gettimeofday() is not defined in the posix module anyway. Sigh.
  
  proc posix_gettimeofday(tp: var Ttimeval, unused: pointer = nil) {.
    importc: "gettimeofday", header: "<sys/time.h>".}

elif defined(windows):
  import winlean
  
  when defined(vcc):
    # newest version of Visual C++ defines time_t to be of 64 bits
    type TTimeImpl {.importc: "time_t", header: "<time.h>".} = int64
  else:
    type TTimeImpl {.importc: "time_t", header: "<time.h>".} = int32
  
  type
    TTime* = distinct TTimeImpl

elif defined(JS):
  type
    TTime* {.final, importc.} = object
      getDay: proc (): int {.tags: [], raises: [].}
      getFullYear: proc (): int {.tags: [], raises: [].}
      getHours: proc (): int {.tags: [], raises: [].}
      getMilliseconds: proc (): int {.tags: [], raises: [].}
      getMinutes: proc (): int {.tags: [], raises: [].}
      getMonth: proc (): int {.tags: [], raises: [].}
      getSeconds: proc (): int {.tags: [], raises: [].}
      getTime: proc (): int {.tags: [], raises: [].}
      getTimezoneOffset: proc (): int {.tags: [], raises: [].}
      getDate: proc (): int {.tags: [], raises: [].}
      getUTCDate: proc (): int {.tags: [], raises: [].}
      getUTCFullYear: proc (): int {.tags: [], raises: [].}
      getUTCHours: proc (): int {.tags: [], raises: [].}
      getUTCMilliseconds: proc (): int {.tags: [], raises: [].}
      getUTCMinutes: proc (): int {.tags: [], raises: [].}
      getUTCMonth: proc (): int {.tags: [], raises: [].}
      getUTCSeconds: proc (): int {.tags: [], raises: [].}
      getUTCDay: proc (): int {.tags: [], raises: [].}
      getYear: proc (): int {.tags: [], raises: [].}
      parse: proc (s: cstring): TTime {.tags: [], raises: [].}
      setDate: proc (x: int) {.tags: [], raises: [].}
      setFullYear: proc (x: int) {.tags: [], raises: [].}
      setHours: proc (x: int) {.tags: [], raises: [].}
      setMilliseconds: proc (x: int) {.tags: [], raises: [].}
      setMinutes: proc (x: int) {.tags: [], raises: [].}
      setMonth: proc (x: int) {.tags: [], raises: [].}
      setSeconds: proc (x: int) {.tags: [], raises: [].}
      setTime: proc (x: int) {.tags: [], raises: [].}
      setUTCDate: proc (x: int) {.tags: [], raises: [].}
      setUTCFullYear: proc (x: int) {.tags: [], raises: [].}
      setUTCHours: proc (x: int) {.tags: [], raises: [].}
      setUTCMilliseconds: proc (x: int) {.tags: [], raises: [].}
      setUTCMinutes: proc (x: int) {.tags: [], raises: [].}
      setUTCMonth: proc (x: int) {.tags: [], raises: [].}
      setUTCSeconds: proc (x: int) {.tags: [], raises: [].}
      setYear: proc (x: int) {.tags: [], raises: [].}
      toGMTString: proc (): cstring {.tags: [], raises: [].}
      toLocaleString: proc (): cstring {.tags: [], raises: [].}

type
  TTimeInfo* = object of TObject ## represents a time in different parts
    second*: range[0..61]     ## The number of seconds after the minute,
                              ## normally in the range 0 to 59, but can
                              ## be up to 61 to allow for leap seconds.
    minute*: range[0..59]     ## The number of minutes after the hour,
                              ## in the range 0 to 59.
    hour*: range[0..23]       ## The number of hours past midnight,
                              ## in the range 0 to 23.
    monthday*: range[1..31]   ## The day of the month, in the range 1 to 31.
    month*: TMonth            ## The current month.
    year*: range[-10_000..10_000] ## The current year.
    weekday*: TWeekDay        ## The current day of the week.
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
  TTimeInterval* {.pure.} = object ## a time interval
    miliseconds*: int ## The number of miliseconds
    seconds*: int     ## The number of seconds
    minutes*: int     ## The number of minutes
    hours*: int       ## The number of hours
    days*: int        ## The number of days
    months*: int      ## The number of months
    years*: int       ## The number of years

proc getTime*(): TTime {.tags: [FTime].}
  ## gets the current calendar time as a UNIX epoch value (number of seconds
  ## elapsed since 1970) with integer precission. Use epochTime for higher
  ## resolution.
proc getLocalTime*(t: TTime): TTimeInfo {.tags: [FTime], raises: [].}
  ## converts the calendar time `t` to broken-time representation,
  ## expressed relative to the user's specified time zone.
proc getGMTime*(t: TTime): TTimeInfo {.tags: [FTime], raises: [].}
  ## converts the calendar time `t` to broken-down time representation,
  ## expressed in Coordinated Universal Time (UTC).

proc timeInfoToTime*(timeInfo: TTimeInfo): TTime {.tags: [].}
  ## converts a broken-down time structure to
  ## calendar time representation. The function ignores the specified
  ## contents of the structure members `weekday` and `yearday` and recomputes
  ## them from the other information in the broken-down time structure.

proc fromSeconds*(since1970: float): TTime {.tags: [], raises: [].}
  ## Takes a float which contains the number of seconds since the unix epoch and
  ## returns a time object.

proc fromSeconds*(since1970: int64): TTime {.tags: [], raises: [].} = 
  ## Takes an int which contains the number of seconds since the unix epoch and
  ## returns a time object.
  fromSeconds(float(since1970))

proc toSeconds*(time: TTime): float {.tags: [], raises: [].}
  ## Returns the time in seconds since the unix epoch.

proc `$` *(timeInfo: TTimeInfo): string {.tags: [], raises: [].}
  ## converts a `TTimeInfo` object to a string representation.
proc `$` *(time: TTime): string {.tags: [], raises: [].}
  ## converts a calendar time to a string representation.

proc `-`*(a, b: TTime): int64 {.
  rtl, extern: "ntDiffTime", tags: [], raises: [].}
  ## computes the difference of two calendar times. Result is in seconds.

proc `<`*(a, b: TTime): bool {.
  rtl, extern: "ntLtTime", tags: [], raises: [].} = 
  ## returns true iff ``a < b``, that is iff a happened before b.
  result = a - b < 0
  
proc `<=` * (a, b: TTime): bool {.
  rtl, extern: "ntLeTime", tags: [], raises: [].}= 
  ## returns true iff ``a <= b``.
  result = a - b <= 0

proc `==`*(a, b: TTime): bool {.
  rtl, extern: "ntEqTime", tags: [], raises: [].} =
  ## returns true if ``a == b``, that is if both times represent the same value
  result = a - b == 0

when not defined(JS):
  proc getTzname*(): tuple[nonDST, DST: string] {.tags: [FTime], raises: [].}
    ## returns the local timezone; ``nonDST`` is the name of the local non-DST
    ## timezone, ``DST`` is the name of the local DST timezone.

proc getTimezone*(): int {.tags: [FTime], raises: [].}
  ## returns the offset of the local (non-DST) timezone in seconds west of UTC.

proc getStartMilsecs*(): int {.deprecated, tags: [FTime].}
  ## get the miliseconds from the start of the program. **Deprecated since
  ## version 0.8.10.** Use ``epochTime`` or ``cpuTime`` instead.

proc initInterval*(miliseconds, seconds, minutes, hours, days, months, 
                   years: int = 0): TTimeInterval =
  ## creates a new ``TTimeInterval``.
  result.miliseconds = miliseconds
  result.seconds = seconds
  result.minutes = minutes
  result.hours = hours
  result.days = days
  result.months = months
  result.years = years

proc isLeapYear(year: int): bool =
  if year mod 400 == 0:
    return true
  elif year mod 100 == 0: 
    return false
  elif year mod 4 == 0: 
    return true
  else:
    return false

proc getDaysInMonth(month: TMonth, year: int): int =
  # http://www.dispersiondesign.com/articles/time/number_of_days_in_a_month
  case month 
  of mFeb: result = if isLeapYear(year): 29 else: 28
  of mApr, mJun, mSep, mNov: result = 30
  else: result = 31

proc toSeconds(a: TTimeInfo, interval: TTimeInterval): float =
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

proc `+`*(a: TTimeInfo, interval: TTimeInterval): TTimeInfo =
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

proc `-`*(a: TTimeInfo, interval: TTimeInterval): TTimeInfo =
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
  proc epochTime*(): float {.rtl, extern: "nt$1", tags: [FTime].}
    ## gets time after the UNIX epoch (1970) in seconds. It is a float
    ## because sub-second resolution is likely to be supported (depending 
    ## on the hardware/OS).

  proc cpuTime*(): float {.rtl, extern: "nt$1", tags: [FTime].}
    ## gets time spent that the CPU spent to run the current process in
    ## seconds. This may be more useful for benchmarking than ``epochTime``.
    ## However, it may measure the real time instead (depending on the OS).
    ## The value of the result has no meaning. 
    ## To generate useful timing values, take the difference between 
    ## the results of two ``cpuTime`` calls:
    ##
    ## .. code-block:: nimrod
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
  
    PTimeInfo = ptr StructTM
    PTime = ptr TTime
  
    TClock {.importc: "clock_t".} = distinct int
  
  proc localtime(timer: PTime): PTimeInfo {.
    importc: "localtime", header: "<time.h>", tags: [].}
  proc gmtime(timer: PTime): PTimeInfo {.
    importc: "gmtime", header: "<time.h>", tags: [].}
  proc timec(timer: PTime): TTime {.
    importc: "time", header: "<time.h>", tags: [].}
  proc mktime(t: StructTM): TTime {.
    importc: "mktime", header: "<time.h>", tags: [].}
  proc asctime(tblock: StructTM): cstring {.
    importc: "asctime", header: "<time.h>", tags: [].}
  proc ctime(time: PTime): cstring {.
    importc: "ctime", header: "<time.h>", tags: [].}
  #  strftime(s: CString, maxsize: int, fmt: CString, t: tm): int {.
  #    importc: "strftime", header: "<time.h>".}
  proc clock(): TClock {.importc: "clock", header: "<time.h>", tags: [FTime].}
  proc difftime(a, b: TTime): float {.importc: "difftime", header: "<time.h>", 
    tags: [].}
  
  var
    clocksPerSec {.importc: "CLOCKS_PER_SEC", nodecl.}: int
    
  # our own procs on top of that:
  proc tmToTimeInfo(tm: StructTM, local: bool): TTimeInfo =
    const
      weekDays: array [0..6, TWeekDay] = [
        dSun, dMon, dTue, dWed, dThu, dFri, dSat]
    TTimeInfo(second: int(tm.second),
      minute: int(tm.minute),
      hour: int(tm.hour),
      monthday: int(tm.monthday),
      month: TMonth(tm.month),
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
  
  proc timeInfoToTM(t: TTimeInfo): StructTM =
    const
      weekDays: array [TWeekDay, int8] = [1'i8,2'i8,3'i8,4'i8,5'i8,6'i8,0'i8]
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
    proc `-` (a, b: TTime): int64 =
      return toBiggestInt(difftime(a, b))
  
  proc getStartMilsecs(): int =
    #echo "clocks per sec: ", clocksPerSec, "clock: ", int(clock())
    #return clock() div (clocksPerSec div 1000)
    when defined(macosx):
      result = toInt(toFloat(int(clock())) / (toFloat(clocksPerSec) / 1000.0))
    else:
      result = int(clock()) div (clocksPerSec div 1000)
    when false:
      var a: Ttimeval
      posix_gettimeofday(a)
      result = a.tv_sec * 1000'i64 + a.tv_usec div 1000'i64
      #echo "result: ", result
    
  proc getTime(): TTime = return timec(nil)
  proc getLocalTime(t: TTime): TTimeInfo =
    var a = t
    result = tmToTimeInfo(localtime(addr(a))[], true)
    # copying is needed anyway to provide reentrancity; thus
    # the conversion is not expensive
  
  proc getGMTime(t: TTime): TTimeInfo =
    var a = t
    result = tmToTimeInfo(gmtime(addr(a))[], false)
    # copying is needed anyway to provide reentrancity; thus
    # the conversion is not expensive
  
  proc timeInfoToTime(timeInfo: TTimeInfo): TTime =
    var cTimeInfo = timeInfo # for C++ we have to make a copy,
    # because the header of mktime is broken in my version of libc
    return mktime(timeInfoToTM(cTimeInfo))

  proc toStringTillNL(p: cstring): string = 
    result = ""
    var i = 0
    while p[i] != '\0' and p[i] != '\10' and p[i] != '\13': 
      add(result, p[i])
      inc(i)
    
  proc `$`(timeInfo: TTimeInfo): string =
    # BUGFIX: asctime returns a newline at the end!
    var p = asctime(timeInfoToTM(timeInfo))
    result = toStringTillNL(p)
  
  proc `$`(time: TTime): string =
    # BUGFIX: ctime returns a newline at the end!
    var a = time
    return toStringTillNL(ctime(addr(a)))

  const
    epochDiff = 116444736000000000'i64
    rateDiff = 10000000'i64 # 100 nsecs

  proc unixTimeToWinTime*(t: TTime): int64 = 
    ## converts a UNIX `TTime` (``time_t``) to a Windows file time
    result = int64(t) * rateDiff + epochDiff
    
  proc winTimeToUnixTime*(t: int64): TTime = 
    ## converts a Windows time to a UNIX `TTime` (``time_t``)
    result = TTime((t - epochDiff) div rateDiff)
 
  proc getTzname(): tuple[nonDST, DST: string] =
    return ($tzname[0], $tzname[1])
  
  proc getTimezone(): int =
    return timezone

  proc fromSeconds(since1970: float): TTime = TTime(since1970)

  proc toSeconds(time: TTime): float = float(time)

  when not defined(useNimRtl):
    proc epochTime(): float = 
      when defined(posix):
        var a: Ttimeval
        posix_gettimeofday(a)
        result = toFloat(a.tv_sec) + toFloat(a.tv_usec)*0.00_0001
      elif defined(windows):
        var f: winlean.TFiletime
        getSystemTimeAsFileTime(f)
        var i64 = rdFileTime(f) - epochDiff
        var secs = i64 div rateDiff
        var subsecs = i64 mod rateDiff
        result = toFloat(int(secs)) + toFloat(int(subsecs)) * 0.0000001
      else:
        {.error: "unknown OS".}
      
    proc cpuTime(): float = 
      result = toFloat(int(clock())) / toFloat(clocksPerSec)
    
elif defined(JS):
  proc newDate(): TTime {.importc: "new Date".}
  proc internGetTime(): TTime {.importc: "new Date", tags: [].}
  
  proc newDate(value: float): TTime {.importc: "new Date".}
  proc newDate(value: string): TTime {.importc: "new Date".}
  proc getTime(): TTime =
    # Warning: This is something different in JS.
    return newDate()

  const
    weekDays: array [0..6, TWeekDay] = [
      dSun, dMon, dTue, dWed, dThu, dFri, dSat]
  
  proc getLocalTime(t: TTime): TTimeInfo =
    result.second = t.getSeconds()
    result.minute = t.getMinutes()
    result.hour = t.getHours()
    result.monthday = t.getDate()
    result.month = TMonth(t.getMonth())
    result.year = t.getFullYear()
    result.weekday = weekDays[t.getDay()]
    result.yearday = 0

  proc getGMTime(t: TTime): TTimeInfo =
    result.second = t.getUTCSeconds()
    result.minute = t.getUTCMinutes()
    result.hour = t.getUTCHours()
    result.monthday = t.getUTCDate()
    result.month = TMonth(t.getUTCMonth())
    result.year = t.getUTCFullYear()
    result.weekday = weekDays[t.getUTCDay()]
    result.yearday = 0
  
  proc timeInfoToTime*(timeInfo: TTimeInfo): TTime =
    result = internGetTime()
    result.setSeconds(timeInfo.second)
    result.setMinutes(timeInfo.minute)
    result.setHours(timeInfo.hour)
    result.setMonth(ord(timeInfo.month))
    result.setFullYear(timeInfo.year)
    result.setDate(timeInfo.monthday)
  
  proc `$`(timeInfo: TTimeInfo): string = return $(TimeInfoToTIme(timeInfo))
  proc `$`(time: TTime): string = return $time.toLocaleString()
    
  proc `-` (a, b: TTime): int64 = 
    return a.getTime() - b.getTime()
  
  var
    startMilsecs = getTime()
  
  proc getStartMilsecs(): int =
    ## get the miliseconds from the start of the program
    return int(getTime() - startMilsecs)

  proc valueOf(time: TTime): float {.importcpp: "getTime", tags:[]}

  proc fromSeconds(since1970: float): TTime = result = newDate(since1970)

  proc toSeconds(time: TTime): float = result = time.valueOf() / 1000

  proc getTimezone(): int = result = newDate().getTimezoneOffset()

proc getDateStr*(): string {.rtl, extern: "nt$1", tags: [FTime].} =
  ## gets the current date as a string of the format ``YYYY-MM-DD``.
  var ti = getLocalTime(getTime())
  result = $ti.year & '-' & intToStr(ord(ti.month)+1, 2) &
    '-' & intToStr(ti.monthday, 2)

proc getClockStr*(): string {.rtl, extern: "nt$1", tags: [FTime].} =
  ## gets the current clock time as a string of the format ``HH:MM:SS``.
  var ti = getLocalTime(getTime())
  result = intToStr(ti.hour, 2) & ':' & intToStr(ti.minute, 2) &
    ':' & intToStr(ti.second, 2)

proc `$`*(day: TWeekDay): string =
  ## stingify operator for ``TWeekDay``.
  const lookup: array[TWeekDay, string] = ["Monday", "Tuesday", "Wednesday",
     "Thursday", "Friday", "Saturday", "Sunday"]
  return lookup[day]

proc `$`*(m: TMonth): string =
  ## stingify operator for ``TMonth``.
  const lookup: array[TMonth, string] = ["January", "February", "March", 
      "April", "May", "June", "July", "August", "September", "October",
      "November", "December"]
  return lookup[m]

proc format*(info: TTimeInfo, f: string): string =
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
  ## Other strings can be inserted by putting them in ``''``. For example ``hh'->'mm`` will give ``01->56``.
  ## The following characters can be inserted without quoting them: ``:`` ``-`` ``(`` ``)`` ``/`` ``[`` ``]`` ``,``

  result = ""
  var i = 0
  var currentF = ""
  while true:
    case f[i]
    of ' ', '-', '/', ':', '\'', '\0', '(', ')', '[', ']', ',':
      case currentF
      of "d":
        result.add($info.monthday)
      of "dd":
        if info.monthday < 10:
          result.add("0")
        result.add($info.monthday)
      of "ddd":
        result.add(($info.weekday)[0 .. 2])
      of "dddd":
        result.add($info.weekday)
      of "h":
        result.add($(if info.hour > 12: info.hour - 12 else: info.hour))
      of "hh":
        let amerHour = if info.hour > 12: info.hour - 12 else: info.hour
        if amerHour < 10:
          result.add('0')
        result.add($amerHour)
      of "H":
        result.add($info.hour)
      of "HH":
        if info.hour < 10:
          result.add('0')
        result.add($info.hour)
      of "m":
        result.add($info.minute)
      of "mm":
        if info.minute < 10:
          result.add('0')
        result.add($info.minute)
      of "M":
        result.add($(int(info.month)+1))
      of "MM":
        if info.month < mOct:
          result.add('0')
        result.add($(int(info.month)+1))
      of "MMM":
        result.add(($info.month)[0..2])
      of "MMMM":
        result.add($info.month)
      of "s":
        result.add($info.second)
      of "ss":
        if info.second < 10:
          result.add('0')
        result.add($info.second)
      of "t":
        if info.hour >= 12:
          result.add('P')
        else: result.add('A')
      of "tt":
        if info.hour >= 12:
          result.add("PM")
        else: result.add("AM")
      of "y":
        var fr = ($info.year).len()-1
        if fr < 0: fr = 0
        result.add(($info.year)[fr .. ($info.year).len()-1])
      of "yy":
        var fr = ($info.year).len()-2
        if fr < 0: fr = 0
        var fyear = ($info.year)[fr .. ($info.year).len()-1]
        if fyear.len != 2: fyear = repeatChar(2-fyear.len(), '0') & fyear
        result.add(fyear)
      of "yyy":
        var fr = ($info.year).len()-3
        if fr < 0: fr = 0
        var fyear = ($info.year)[fr .. ($info.year).len()-1]
        if fyear.len != 3: fyear = repeatChar(3-fyear.len(), '0') & fyear
        result.add(fyear)
      of "yyyy":
        var fr = ($info.year).len()-4
        if fr < 0: fr = 0
        var fyear = ($info.year)[fr .. ($info.year).len()-1]
        if fyear.len != 4: fyear = repeatChar(4-fyear.len(), '0') & fyear
        result.add(fyear)
      of "yyyyy":
        var fr = ($info.year).len()-5
        if fr < 0: fr = 0
        var fyear = ($info.year)[fr .. ($info.year).len()-1]
        if fyear.len != 5: fyear = repeatChar(5-fyear.len(), '0') & fyear
        result.add(fyear)
      of "z":
        let hrs = (info.timezone div 60) div 60
        result.add($hrs)
      of "zz":
        let hrs = (info.timezone div 60) div 60
        
        result.add($hrs)
        if hrs.abs < 10:
          var atIndex = result.len-(($hrs).len-(if hrs < 0: 1 else: 0))
          result.insert("0", atIndex)
      of "zzz":
        let hrs = (info.timezone div 60) div 60
        
        result.add($hrs & ":00")
        if hrs.abs < 10:
          var atIndex = result.len-(($hrs & ":00").len-(if hrs < 0: 1 else: 0))
          result.insert("0", atIndex)
      of "ZZZ":
        result.add(info.tzname)
      of "":
        discard
      else:
        raise newException(EInvalidValue, "Invalid format string: " & currentF)
      
      currentF = ""
      if f[i] == '\0': break
      
      if f[i] == '\'':
        inc(i) # Skip '
        while f[i] != '\'' and f.len-1 > i:
          result.add(f[i])
          inc(i)
      else: result.add(f[i])
      
    else: currentF.add(f[i])
    inc(i)

{.pop.}

when isMainModule:
  # $ date --date='@2147483647'
  # Tue 19 Jan 03:14:07 GMT 2038

  var t = getGMTime(fromSeconds(2147483647))
  echo t.format("ddd dd MMM hh:mm:ss ZZZ yyyy")
  assert t.format("ddd dd MMM hh:mm:ss ZZZ yyyy") == "Tue 19 Jan 03:14:07 UTC 2038"
  
  assert t.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
    " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") == 
    "19 19 Tue Tuesday 3 03 3 03 14 14 1 01 Jan January 7 07 A AM 8 38 038 2038 02038 0 00 00:00 UTC"
  
  var t2 = getGMTime(fromSeconds(160070789)) # Mon 27 Jan 16:06:29 GMT 1975
  assert t2.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
    " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
    "27 27 Mon Monday 4 04 16 16 6 06 1 01 Jan January 29 29 P PM 5 75 975 1975 01975 0 00 00:00 UTC"
  
  when not defined(JS) and sizeof(TTime) == 8:
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
