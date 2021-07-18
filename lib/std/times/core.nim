#
#
#            Nim's Runtime Library
#        (c) Copyright 2021 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## The `std/times/core` module contains some core definitions for dealing with time.
## It is reexported by the `std/times` module.

import std/strutils

include "system/inclrtl"

type
  Month* = enum
    ## Represents a month. Note that the enum starts at `1`,
    ## so `ord(month)` will give the month number in the
    ## range `1..12`.
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
    ## Includes the value 60 to allow for a leap second. Note however
    ## that the `second` of a `DateTime` will never be a leap second.
  YeardayRange* = range[0..365]
  NanosecondRange* = range[0..999_999_999]

  TimeUnit* = enum ## Different units of time.
    Nanoseconds, Microseconds, Milliseconds, Seconds, Minutes, Hours, Days,
    Weeks, Months, Years

  FixedTimeUnit* = range[Nanoseconds..Weeks]
    ## Subrange of `TimeUnit` that only includes units of fixed duration.
    ## These are the units that can be represented by a `Duration`.

const
  secondsInMin = 60
  secondsInHour = 60*60
  secondsInDay = 60*60*24

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

{.pragma: operator, rtl, noSideEffect, benign.}

proc convert*[T: SomeInteger](unitFrom, unitTo: FixedTimeUnit, quantity: T): T {.inline.} =
  ## Convert a quantity of some duration unit to another duration unit.
  ## This proc only deals with integers, so the result might be truncated.
  runnableExamples:
    doAssert convert(Days, Hours, 2) == 48
    doAssert convert(Days, Weeks, 13) == 1 # Truncated
    doAssert convert(Seconds, Milliseconds, -1) == -1000
  if unitFrom < unitTo:
    (quantity div (unitWeights[unitTo] div unitWeights[unitFrom])).T
  else:
    ((unitWeights[unitFrom] div unitWeights[unitTo]) * quantity).T

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
