#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time.
## This module is available for the ECMAScript target.

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

when defined(posix): 
  type
    TTimeImpl {.importc: "time_t", header: "<sys/time.h>".} = int
    TTime* = distinct TTimeImpl ## distinct type that represents a time
    
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

elif defined(ECMAScript):
  type
    TTime* {.final, importc.} = object
      getDay: proc (): int
      getFullYear: proc (): int
      getHours: proc (): int
      getMilliseconds: proc (): int
      getMinutes: proc (): int
      getMonth: proc (): int
      getSeconds: proc (): int
      getTime: proc (): int
      getTimezoneOffset: proc (): int
      getDate: proc (): int
      getUTCDate: proc (): int
      getUTCFullYear: proc (): int
      getUTCHours: proc (): int
      getUTCMilliseconds: proc (): int
      getUTCMinutes: proc (): int
      getUTCMonth: proc (): int
      getUTCSeconds: proc (): int
      getYear: proc (): int
      parse: proc (s: cstring): TTime
      setDate: proc (x: int)
      setFullYear: proc (x: int)
      setHours: proc (x: int)
      setMilliseconds: proc (x: int)
      setMinutes: proc (x: int)
      setMonth: proc (x: int)
      setSeconds: proc (x: int)
      setTime: proc (x: int)
      setUTCDate: proc (x: int)
      setUTCFullYear: proc (x: int)
      setUTCHours: proc (x: int)
      setUTCMilliseconds: proc (x: int)
      setUTCMinutes: proc (x: int)
      setUTCMonth: proc (x: int)
      setUTCSeconds: proc (x: int)
      setYear: proc (x: int)
      toGMTString: proc (): cstring
      toLocaleString: proc (): cstring
      UTC: proc (): int

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
                              ## Always 0 if the target is ECMAScript.
    isDST*: bool              ## Determines whether DST is in effect. Always
                              ## ``False`` if time is UTC.
    tzname*: string           ## The timezone this time is in. E.g. GMT
    timezone*: int            ## The offset of the (non-DST) timezone in seconds
                              ## west of UTC.

  TTimeInterval* {.pure.} = object ## a time interval
    miliseconds*: int ## The number of miliseconds
    seconds*: int     ## The number of seconds
    minutes*: int     ## The number of minutes
    hours*: int       ## The number of hours
    days*: int        ## The number of days
    months*: int      ## The number of months
    years*: int       ## The number of years

proc getTime*(): TTime ## gets the current calendar time
proc getLocalTime*(t: TTime): TTimeInfo
  ## converts the calendar time `t` to broken-time representation,
  ## expressed relative to the user's specified time zone.
proc getGMTime*(t: TTime): TTimeInfo
  ## converts the calendar time `t` to broken-down time representation,
  ## expressed in Coordinated Universal Time (UTC).

proc TimeInfoToTime*(timeInfo: TTimeInfo): TTime
  ## converts a broken-down time structure to
  ## calendar time representation. The function ignores the specified
  ## contents of the structure members `weekday` and `yearday` and recomputes
  ## them from the other information in the broken-down time structure.

proc `$` *(timeInfo: TTimeInfo): string
  ## converts a `TTimeInfo` object to a string representation.
proc `$` *(time: TTime): string
  ## converts a calendar time to a string representation.

proc `-`*(a, b: TTime): int64 {.
  rtl, extern: "ntDiffTime".}
  ## computes the difference of two calendar times. Result is in seconds.

proc `<`*(a, b: TTime): bool {.
  rtl, extern: "ntLtTime".} = 
  ## returns true iff ``a < b``, that is iff a happened before b.
  result = a - b < 0
  
proc `<=` * (a, b: TTime): bool {.
  rtl, extern: "ntLeTime".}= 
  ## returns true iff ``a <= b``.
  result = a - b <= 0

proc getTzname*(): tuple[nonDST, DST: string]
  ## returns the local timezone; ``nonDST`` is the name of the local non-DST
  ## timezone, ``DST`` is the name of the local DST timezone.

proc getTimezone*(): int
  ## returns the offset of the local (non-DST) timezone in seconds west of UTC.

proc getStartMilsecs*(): int {.deprecated.}
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

proc calculateSeconds(a: TTimeInfo, interval: TTimeInterval): float =
  var anew = a
  var newinterv = interval
  result = 0.0
  
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
  result += float(newinterv.minutes * 60 * 60)
  result += newinterv.seconds.float
  result += newinterv.miliseconds / 1000

proc `+`*(a: TTimeInfo, interval: TTimeInterval): TTimeInfo =
  ## adds ``interval`` time.
  ##
  ## **Note:** This has been only briefly tested and it may not be
  ## very accurate.
  let t = timeInfoToTime(a)
  let secs = calculateSeconds(a, interval)
  if a.tzname == "UTC":
    result = getGMTime(TTime(float(t) + secs))
  else:
    result = getLocalTime(TTime(float(t) + secs))

proc `-`*(a: TTimeInfo, interval: TTimeInterval): TTimeInfo =
  ## subtracts ``interval`` time.
  ##
  ## **Note:** This has been only briefly tested, it is inaccurate especially
  ## when you subtract so much that you reach the Julian calendar.
  let t = timeInfoToTime(a)
  let secs = calculateSeconds(a, interval)
  if a.tzname == "UTC":
    result = getGMTime(TTime(float(t) - secs))
  else:
    result = getLocalTime(TTime(float(t) - secs))

when not defined(ECMAScript):  
  proc epochTime*(): float {.rtl, extern: "nt$1".}
    ## gets time after the UNIX epoch (1970) in seconds. It is a float
    ## because sub-second resolution is likely to be supported (depending 
    ## on the hardware/OS).

  proc cpuTime*(): float {.rtl, extern: "nt$1".}
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

when not defined(ECMAScript):
  
  # C wrapper:
  type
    structTM {.importc: "struct tm", final.} = object
      second {.importc: "tm_sec".},
        minute {.importc: "tm_min".},
        hour {.importc: "tm_hour".},
        monthday {.importc: "tm_mday".},
        month {.importc: "tm_mon".},
        year {.importc: "tm_year".},
        weekday {.importc: "tm_wday".},
        yearday {.importc: "tm_yday".},
        isdst {.importc: "tm_isdst".}: cint
  
    PTimeInfo = ptr structTM
    PTime = ptr TTime
  
    TClock {.importc: "clock_t".} = distinct int
  
  proc localtime(timer: PTime): PTimeInfo {.
    importc: "localtime", header: "<time.h>".}
  proc gmtime(timer: PTime): PTimeInfo {.importc: "gmtime", header: "<time.h>".}
  proc timec(timer: PTime): TTime      {.importc: "time", header: "<time.h>".}
  proc mktime(t: structTM): TTime      {.importc: "mktime", header: "<time.h>".}
  proc asctime(tblock: structTM): CString {.
    importc: "asctime", header: "<time.h>".}
  proc ctime(time: PTime): CString     {.importc: "ctime", header: "<time.h>".}
  #  strftime(s: CString, maxsize: int, fmt: CString, t: tm): int {.
  #    importc: "strftime", header: "<time.h>".}
  proc clock(): TClock {.importc: "clock", header: "<time.h>".}
  proc difftime(a, b: TTime): float {.importc: "difftime", header: "<time.h>".}
  
  var
    clocksPerSec {.importc: "CLOCKS_PER_SEC", nodecl.}: int
    
  # our own procs on top of that:
  proc tmToTimeInfo(tm: structTM, local: bool): TTimeInfo =
    const
      weekDays: array [0..6, TWeekDay] = [
        dSun, dMon, dTue, dWed, dThu, dFri, dSat]
    result.second = int(tm.second)
    result.minute = int(tm.minute)
    result.hour = int(tm.hour)
    result.monthday = int(tm.monthday)
    result.month = TMonth(tm.month)
    result.year = tm.year + 1900'i32
    result.weekday = weekDays[int(tm.weekDay)]
    result.yearday = int(tm.yearday)
    result.isDST = tm.isDST > 0
    if local:
      if result.isDST:
        result.tzname = getTzname()[0]
      if not result.isDST:
        result.tzname = getTzname()[1]
    else:
      result.tzname = "UTC"
    
    result.timezone = if local: getTimezone() else: 0
  
  proc timeInfoToTM(t: TTimeInfo): structTM =
    const
      weekDays: array [TWeekDay, int8] = [1'i8,2'i8,3'i8,4'i8,5'i8,6'i8,0'i8]
    result.second = t.second
    result.minute = t.minute
    result.hour = t.hour
    result.monthday = t.monthday
    result.month = ord(t.month)
    result.year = t.year - 1900
    result.weekday = weekDays[t.weekDay]
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
  
  proc TimeInfoToTime(timeInfo: TTimeInfo): TTime =
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
  
  when not defined(useNimRtl):
    proc epochTime(): float = 
      when defined(posix):
        var a: Ttimeval
        posix_gettimeofday(a)
        result = toFloat(a.tv_sec) + toFloat(a.tv_usec)*0.00_0001
      elif defined(windows):
        var f: winlean.TFiletime
        GetSystemTimeAsFileTime(f)
        var i64 = rdFileTime(f) - epochDiff
        var secs = i64 div rateDiff
        var subsecs = i64 mod rateDiff
        result = toFloat(int(secs)) + toFloat(int(subsecs)) * 0.0000001
      else:
        {.error: "unknown OS".}
      
    proc cpuTime(): float = 
      result = toFloat(int(clock())) / toFloat(clocksPerSec)
    
else:
  proc newDate(): TTime {.importc: "new Date", nodecl.}
  proc getTime(): TTime = return newDate()

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
    result.weekday = weekDays[t.getDay()]
    result.yearday = 0
  
  proc TimeInfoToTime*(timeInfo: TTimeInfo): TTime =
    result = getTime()
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


proc getDateStr*(): string {.rtl, extern: "nt$1".} =
  ## gets the current date as a string of the format ``YYYY-MM-DD``.
  var ti = getLocalTime(getTime())
  result = $ti.year & '-' & intToStr(ord(ti.month)+1, 2) &
    '-' & intToStr(ti.monthDay, 2)

proc getClockStr*(): string {.rtl, extern: "nt$1".} =
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

  result = ""
  var i = 0
  var currentF = ""
  while True:
    case f[i]
    of ' ', '-', '/', ':', '\'', '\0':
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
        result.add($(info.hour - 12))
      of "hh":
        let amerHour = info.hour - 12
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
        if int(info.month) < 10:
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
        var fr = ($info.year).len()-2
        if fr < 0: fr = 0
        result.add(($info.year)[fr .. ($info.year).len()-1])
      of "yy":
        var fr = ($info.year).len()-3
        if fr < 0: fr = 0
        result.add(($info.year)[fr .. ($info.year).len()-1])
      of "yyy":
        var fr = ($info.year).len()-4
        if fr < 0: fr = 0
        result.add(($info.year)[fr .. ($info.year).len()-1])
      of "yyyy":
        result.add($info.year)
      of "yyyyy":
        result.add('0')
        result.add($info.year)
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
        nil # Do nothing.
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
