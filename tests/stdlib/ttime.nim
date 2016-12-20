# test the new time module
discard """
  file: "ttime.nim"
"""

import
  times, strutils

# $ date --date='@2147483647'
# Tue 19 Jan 03:14:07 GMT 2038

proc checkFormat(t: TimeInfo, format, expected: string) =
  let actual = t.format(format)
  if actual != expected:
    echo "Formatting failure!"
    echo "expected: ", expected
    echo "actual  : ", actual
    doAssert false

let t = getGMTime(fromSeconds(2147483647))
t.checkFormat("ddd dd MMM hh:mm:ss yyyy", "Tue 19 Jan 03:14:07 2038")
t.checkFormat("ddd ddMMMhh:mm:ssyyyy", "Tue 19Jan03:14:072038")
t.checkFormat("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
  " ss t tt y yy yyy yyyy yyyyy z zz zzz",
  "19 19 Tue Tuesday 3 03 3 03 14 14 1 01 Jan January 7 07 A AM 8 38 038 2038 02038 +0 +00 +00:00")

t.checkFormat("yyyyMMddhhmmss", "20380119031407")

let t2 = getGMTime(fromSeconds(160070789)) # Mon 27 Jan 16:06:29 GMT 1975
t2.checkFormat("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
  " ss t tt y yy yyy yyyy yyyyy z zz zzz",
  "27 27 Mon Monday 4 04 16 16 6 06 1 01 Jan January 29 29 P PM 5 75 975 1975 01975 +0 +00 +00:00")

when not defined(JS):
  when sizeof(Time) == 8:
    var t3 = getGMTime(fromSeconds(889067643645)) # Fri  7 Jun 19:20:45 BST 30143
    t3.checkFormat("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
      " ss t tt y yy yyy yyyy yyyyy z zz zzz",
      "7 07 Fri Friday 6 06 18 18 20 20 6 06 Jun June 45 45 P PM 3 43 143 0143 30143 +0 +00 +00:00")
    t3.checkFormat(":,[]()-/", ":,[]()-/")

var t4 = getGMTime(fromSeconds(876124714)) # Mon  6 Oct 08:58:34 BST 1997
t4.checkFormat("M MM MMM MMMM", "10 10 Oct October")

# Interval tests
(t4 - initInterval(years = 2)).checkFormat("yyyy", "1995")
(t4 - initInterval(years = 7, minutes = 34, seconds = 24)).checkFormat("yyyy mm ss", "1990 24 10")

proc parseTest(s, f, sExpected: string, ydExpected: int) =
  let
    parsed = s.parse(f)
    parsedStr = $getGMTime(toTime(parsed))
  if parsedStr != sExpected:
    echo "Parsing failure!"
    echo "expected: ", sExpected
    echo "actual  : ", parsedStr
    doAssert false
  doAssert(parsed.yearday == ydExpected)
proc parseTestTimeOnly(s, f, sExpected: string) =
  doAssert(sExpected in $s.parse(f))

# because setting a specific timezone for testing is platform-specific, we use
# explicit timezone offsets in all tests.

parseTest("Tuesday at 09:04am on Dec 15, 2015 +0",
    "dddd at hh:mmtt on MMM d, yyyy z", "2015-12-15T09:04:00+00:00", 348)
# ANSIC       = "Mon Jan _2 15:04:05 2006"
parseTest("Thu Jan 12 15:04:05 2006 +0", "ddd MMM dd HH:mm:ss yyyy z",
    "2006-01-12T15:04:05+00:00", 11)
# UnixDate    = "Mon Jan _2 15:04:05 MST 2006"
parseTest("Thu Jan 12 15:04:05 2006 +0", "ddd MMM dd HH:mm:ss yyyy z",
    "2006-01-12T15:04:05+00:00", 11)
# RubyDate    = "Mon Jan 02 15:04:05 -0700 2006"
parseTest("Mon Feb 29 15:04:05 -07:00 2016 +0", "ddd MMM dd HH:mm:ss zzz yyyy z",
    "2016-02-29T15:04:05+00:00", 59) # leap day
# RFC822      = "02 Jan 06 15:04 MST"
parseTest("12 Jan 16 15:04 +0", "dd MMM yy HH:mm z",
    "2016-01-12T15:04:00+00:00", 11)
# RFC822Z     = "02 Jan 06 15:04 -0700" # RFC822 with numeric zone
parseTest("01 Mar 16 15:04 -07:00", "dd MMM yy HH:mm zzz",
    "2016-03-01T22:04:00+00:00", 60) # day after february in leap year
# RFC850      = "Monday, 02-Jan-06 15:04:05 MST"
parseTest("Monday, 12-Jan-06 15:04:05 +0", "dddd, dd-MMM-yy HH:mm:ss z",
    "2006-01-12T15:04:05+00:00", 11)
# RFC1123     = "Mon, 02 Jan 2006 15:04:05 MST"
parseTest("Sun, 01 Mar 2015 15:04:05 +0", "ddd, dd MMM yyyy HH:mm:ss z",
    "2015-03-01T15:04:05+00:00", 59) # day after february in non-leap year
# RFC1123Z    = "Mon, 02 Jan 2006 15:04:05 -0700" # RFC1123 with numeric zone
parseTest("Thu, 12 Jan 2006 15:04:05 -07:00", "ddd, dd MMM yyyy HH:mm:ss zzz",
    "2006-01-12T22:04:05+00:00", 11)
# RFC3339     = "2006-01-02T15:04:05Z07:00"
parseTest("2006-01-12T15:04:05Z-07:00", "yyyy-MM-ddTHH:mm:ssZzzz",
    "2006-01-12T22:04:05+00:00", 11)
parseTest("2006-01-12T15:04:05Z-07:00", "yyyy-MM-dd'T'HH:mm:ss'Z'zzz",
    "2006-01-12T22:04:05+00:00", 11)
# RFC3339Nano = "2006-01-02T15:04:05.999999999Z07:00"
parseTest("2006-01-12T15:04:05.999999999Z-07:00",
    "yyyy-MM-ddTHH:mm:ss.999999999Zzzz", "2006-01-12T22:04:05+00:00", 11)
for tzFormat in ["z", "zz", "zzz"]:
  # formatting timezone as 'Z' for UTC
  parseTest("2001-01-12T22:04:05Z", "yyyy-MM-dd'T'HH:mm:ss" & tzFormat,
      "2001-01-12T22:04:05+00:00", 11)
# Kitchen     = "3:04PM"
parseTestTimeOnly("3:04PM", "h:mmtt", "15:04:00")
#when not defined(testing):
#  echo "Kitchen: " & $s.parse(f)
#  var ti = timeToTimeInfo(getTime())
#  echo "Todays date after decoding: ", ti
#  var tint = timeToTimeInterval(getTime())
#  echo "Todays date after decoding to interval: ", tint

# checking dayOfWeek matches known days
doAssert getDayOfWeek(21, 9, 1900) == dFri
doAssert getDayOfWeek(1, 1, 1970) == dThu
doAssert getDayOfWeek(21, 9, 1970) == dMon
doAssert getDayOfWeek(1, 1, 2000) == dSat
doAssert getDayOfWeek(1, 1, 2021) == dFri
# Julian tests
doAssert getDayOfWeekJulian(21, 9, 1900) == dFri
doAssert getDayOfWeekJulian(21, 9, 1970) == dMon
doAssert getDayOfWeekJulian(1, 1, 2000) == dSat
doAssert getDayOfWeekJulian(1, 1, 2021) == dFri

# toSeconds tests with GM timezone
let t4L = getGMTime(fromSeconds(876124714))
doAssert toSeconds(toTime(t4L)) == 876124714
doAssert toSeconds(toTime(t4L)) + t4L.timezone.float == toSeconds(toTime(t4))

# adding intervals
var
  a1L = toSeconds(toTime(t4L + initInterval(hours = 1))) + t4L.timezone.float
  a1G = toSeconds(toTime(t4)) + 60.0 * 60.0
doAssert a1L == a1G

# subtracting intervals
a1L = toSeconds(toTime(t4L - initInterval(hours = 1))) + t4L.timezone.float
a1G = toSeconds(toTime(t4)) - (60.0 * 60.0)
doAssert a1L == a1G

# add/subtract TimeIntervals and Time/TimeInfo
doAssert getTime() - 1.seconds == getTime() - 3.seconds + 2.seconds
doAssert getTime() + 65.seconds == getTime() + 1.minutes + 5.seconds
doAssert getTime() + 60.minutes == getTime() + 1.hours
doAssert getTime() + 24.hours == getTime() + 1.days
doAssert getTime() + 13.months == getTime() + 1.years + 1.months
var
  ti1 = getTime() + 1.years
ti1 -= 1.years
doAssert ti1 == getTime()
ti1 += 1.days
doAssert ti1 == getTime() + 1.days

# overflow of TimeIntervals on initalisation
doAssert initInterval(milliseconds = 25000) == initInterval(seconds = 25)
doAssert initInterval(seconds = 65) == initInterval(seconds = 5, minutes = 1)
doAssert initInterval(hours = 25) == initInterval(hours = 1, days = 1)
doAssert initInterval(months = 13) == initInterval(months = 1, years = 1)

# Bug with adding a day to a Time
let day = 24.hours
let tomorrow = getTime() + day
doAssert tomorrow - getTime() == 60*60*24

doAssert milliseconds(1000 * 60) == minutes(1)
doAssert milliseconds(1000 * 60 * 60) == hours(1)
doAssert milliseconds(1000 * 60 * 60 * 24) == days(1)
doAssert seconds(60 * 60) == hours(1)
doAssert seconds(60 * 60 * 24) == days(1)
doAssert seconds(60 * 60 + 65) == (hours(1) + minutes(1) + seconds(5))

# Bug with parse not setting DST properly if the current local DST differs from
# the date being parsed. Need to test parse dates both in and out of DST. We
# are testing that be relying on the fact that tranforming a TimeInfo to a Time
# and back again will correctly set the DST value. With the incorrect parse
# behavior this will introduce a one hour offset from the named time and the
# parsed time if the DST value differs between the current time and the date we
# are parsing.
#
# Unfortunately these tests depend on the locale of the system in which they
# are run. They will not be meaningful when run in a locale without DST. They
# also assume that Jan. 1 and Jun. 1 will have differing isDST values.
let dstT1 = parse("2016-01-01 00:00:00", "yyyy-MM-dd HH:mm:ss")
let dstT2 = parse("2016-06-01 00:00:00", "yyyy-MM-dd HH:mm:ss")
doAssert dstT1 == getLocalTime(toTime(dstT1))
doAssert dstT2 == getLocalTime(toTime(dstT2))

# Comparison between Time objects should be detected by compiler
# as 'noSideEffect'.
proc cmpTimeNoSideEffect(t1: Time, t2: Time): bool {.noSideEffect.} =
  result = t1 == t2
doAssert cmpTimeNoSideEffect(0.fromSeconds, 0.fromSeconds)
# Additionally `==` generic for seq[T] has explicit 'noSideEffect' pragma
# so we can check above condition by comparing seq[Time] sequences
let seqA: seq[Time] = @[]
let seqB: seq[Time] = @[]
doAssert seqA == seqB

for tz in [
    (0, "+0", "+00", "+00:00"), # UTC
    (-3600, "+1", "+01", "+01:00"), # CET
    (-39600, "+11", "+11", "+11:00"), # two digits
    (-1800, "+0", "+00", "+00:30"), # half an hour
    (7200, "-2", "-02", "-02:00"), # positive
    (38700, "-10", "-10", "-10:45")]: # positive with three quaters hour
  let ti = TimeInfo(monthday: 1, timezone: tz[0])
  doAssert ti.format("z") == tz[1]
  doAssert ti.format("zz") == tz[2]
  doAssert ti.format("zzz") == tz[3]

block dstTest:
  let nonDst = TimeInfo(year: 2015, month: mJan, monthday: 01, yearday: 0,
      weekday: dThu, hour: 00, minute: 00, second: 00, isDST: false, timezone: 0)
  var dst = nonDst
  dst.isDst = true
  # note that both isDST == true and isDST == false are valid here because
  # DST is in effect on January 1st in some southern parts of Australia.

  doAssert nonDst.toTime() - dst.toTime() == 3600
  doAssert nonDst.format("z") == "+0"
  doAssert dst.format("z") == "+1"

  # parsing will set isDST in relation to the local time. We take a date in
  # January and one in July to maximize the probability to hit one date with DST
  # and one without on the local machine. However, this is not guaranteed.
  let
    parsedJan = parse("2016-01-05 04:00:00+01:00", "yyyy-MM-dd HH:mm:sszzz")
    parsedJul = parse("2016-07-01 04:00:00+01:00", "yyyy-MM-dd HH:mm:sszzz")
  doAssert toTime(parsedJan) == fromSeconds(1451962800)
  doAssert toTime(parsedJul) == fromSeconds(1467342000)
