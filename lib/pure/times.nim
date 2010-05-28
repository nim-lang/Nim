#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time.
## This module is available for the ECMAScript target.

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

import
  strutils

type
  TMonth* = enum ## represents a month
    mJan, mFeb, mMar, mApr, mMay, mJun, mJul, mAug, mSep, mOct, mNov, mDec
  TWeekDay* = enum ## represents a weekday
    dMon, dTue, dWed, dThu, dFri, dSat, dSun
    
when defined(posix): 
  type
    TTime* = distinct int ## distinct type that represents a time

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
  when defined(vcc):
    # newest version of Visual C++ defines time_t to be of 64 bits
    type TTime* = distinct int64
  else:
    type TTime* = distinct int32
elif defined(ECMAScript):
  type
    TTime* {.final.} = object
      getDay: proc (): int
      getFullYear: proc (): int
      getHours: proc (): int
      getMilliseconds: proc (): int
      getMinutes: proc (): int
      getMonth: proc (): int
      getSeconds: proc (): int
      getTime: proc (): int
      getTimezoneOffset: proc (): int
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
    year*: int                ## The current year.
    weekday*: TWeekDay        ## The current day of the week.
    yearday*: range[0..365]   ## The number of days since January 1,
                              ## in the range 0 to 365.
                              ## Always 0 if the target is ECMAScript.

proc getTime*(): TTime ## gets the current calendar time
proc getLocalTime*(t: TTime): TTimeInfo
  ## converts the calendar time `t` to broken-time representation,
  ## expressed relative to the user's specified time zone.
proc getGMTime*(t: TTime): TTimeInfo
  ## converts the calendar time `t` to broken-down time representation,
  ## expressed in Coordinated Universal Time (UTC).

proc TimeInfoToTime*(timeInfo: TTimeInfo): TTime
  ## converts a broken-down time structure, expressed as local time, to
  ## calendar time representation. The function ignores the specified
  ## contents of the structure members `weekday` and `yearday` and recomputes
  ## them from the other information in the broken-down time structure.

proc `$` *(timeInfo: TTimeInfo): string
  ## converts a `TTimeInfo` object to a string representation.
proc `$` *(time: TTime): string
  ## converts a calendar time to a string representation.

proc getDateStr*(): string
  ## gets the current date as a string of the format
  ## ``YYYY-MM-DD``.
proc getClockStr*(): string
  ## gets the current clock time as a string of the format ``HH:MM:SS``.

proc `-` *(a, b: TTime): int64
  ## computes the difference of two calendar times. Result is in seconds.

proc `<` * (a, b: TTime): bool = 
  ## returns true iff ``a < b``, that is iff a happened before b.
  result = a - b < 0
  
proc `<=` * (a, b: TTime): bool = 
  ## returns true iff ``a <= b``.
  result = a - b <= 0

proc getStartMilsecs*(): int
  ## get the miliseconds from the start of the program


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
  
    TClock {.importc: "clock_t".} = distinct int #range[low(int)..high(int)]
  
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
  proc tmToTimeInfo(tm: structTM): TTimeInfo =
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
  
  proc timeInfoToTM(t: TTimeInfo): structTM =
    const
      weekDays: array [TWeekDay, int] = [1, 2, 3, 4, 5, 6, 0]
    result.second = t.second
    result.minute = t.minute
    result.hour = t.hour
    result.monthday = t.monthday
    result.month = ord(t.month)
    result.year = t.year - 1900
    result.weekday = weekDays[t.weekDay]
    result.yearday = t.yearday
    result.isdst = -1
  
  proc `-` (a, b: TTime): int64 =
    return toBiggestInt(difftime(a, b))
  
  proc getStartMilsecs(): int =
    #echo "clocks per sec: ", clocksPerSec, "clock: ", int(clock())
    #return clock() div (clocksPerSec div 1000)
    when defined(posix):
      var a: Ttimeval
      posix_gettimeofday(a)
      result = a.tv_sec * 1000 + a.tv_usec
    else:
      result = int(clock()) div (clocksPerSec div 1000)
    when false:
      when defined(macosx):
        result = toInt(toFloat(clock()) / (toFloat(clocksPerSec) / 1000.0))
    
  proc getTime(): TTime = return timec(nil)
  proc getLocalTime(t: TTime): TTimeInfo =
    var a = t
    result = tmToTimeInfo(localtime(addr(a))^)
    # copying is needed anyway to provide reentrancity; thus
    # the convertion is not expensive
  
  proc getGMTime(t: TTime): TTimeInfo =
    var a = t
    result = tmToTimeInfo(gmtime(addr(a))^)
    # copying is needed anyway to provide reentrancity; thus
    # the convertion is not expensive
  
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
    return result
    
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

else:
  proc getTime(): TTime {.importc: "new Date", nodecl.}

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
  proc `$`(time: TTime): string = $time.toLocaleString()
    
  proc `-` (a, b: TTime): int64 = 
    return a.getTime() - b.getTime()
  
  var
    startMilsecs = getTime()
  
  proc getStartMilsecs(): int =
    ## get the miliseconds from the start of the program
    return int(getTime() - startMilsecs)

proc getDateStr(): string =
  var ti = getLocalTime(getTime())
  result = $ti.year & '-' & intToStr(ord(ti.month)+1, 2) &
    '-' & intToStr(ti.monthDay, 2)

proc getClockStr(): string =
  var ti = getLocalTime(getTime())
  result = intToStr(ti.hour, 2) & ':' & intToStr(ti.minute, 2) &
    ':' & intToStr(ti.second, 2)

{.pop.}
