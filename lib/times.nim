#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## This module contains routines and types for dealing with time.

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

import
  strutils

type
  TMonth* = enum ## represents a month
    mJan, mFeb, mMar, mApr, mMay, mJun, mJul, mAug, mSep, mOct, mNov, mDec
  TWeekDay* = enum ## represents a weekday
    dMon, dTue, dWed, dThu, dFri, dSat, dSun

  TTime* {.importc: "time_t".} = record ## abstract type that represents a time

  TTimeInfo* = record         ## represents a time in different parts
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
  ## converts a `TTimeInfo` record to a
  ## string representation.
proc `$` *(time: TTime): string
  ## converts a calendar time to a
  ## string representation.

proc getDateStr*(): string
  ## gets the current date as a string of the format
  ## ``YYYY-MM-DD``.
proc getClockStr*(): string
  ## gets the current clock time as a string of the format ``HH:MM:SS``.

proc `-` *(a, b: TTime): int64
  ## computes the difference of two calendar times. Result is in seconds.

proc getStartMilsecs*(): int
  ## get the miliseconds from the start of the program

#implementation

# C wrapper:
type
  structTM {.importc: "struct tm".} = record
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

  TClock {.importc: "clock_t".} = range[low(int)..high(int)]

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
  result.year = tm.year + 1900
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
  return toInt(difftime(a, b)) # XXX: toBiggestInt is needed here, but
                               # Nim does not support it!

proc getStartMilsecs(): int = return clock() div (clocksPerSec div 1000)
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

proc getDateStr(): string =
  var ti = getLocalTime(getTime())
  result = $ti.year & "-" & intToStr(ord(ti.month)+1, 2) &
    "-" & intToStr(ti.monthDay, 2)

proc getClockStr(): string =
  var ti = getLocalTime(getTime())
  result = intToStr(ti.hour, 2) & ':' & intToStr(ti.minute, 2) &
    ':' & intToStr(ti.second, 2)

proc `$`(timeInfo: TTimeInfo): string =
  return $asctime(timeInfoToTM(timeInfo))

proc `$`(time: TTime): string =
  var a = time
  return $ctime(addr(a))

{.pop.}
