discard """
  target: "c js"
"""

import times, strutils, unittest

when not defined(js):
  import os

# Normally testament configures unittest with environment variables,
# but that doesn't work for the JS target. So instead we must set the correct
# settings here.
addOutputFormatter(
  newConsoleOutputFormatter(PRINT_FAILURES, colorOutput = false))

proc staticTz(hours, minutes, seconds: int = 0): Timezone {.noSideEffect.} =
  let offset = hours * 3600 + minutes * 60 + seconds

  proc zonedTimeFromAdjTime(adjTime: Time): ZonedTime {.locks: 0.} =
    result.isDst = false
    result.utcOffset = offset
    result.time = adjTime + initDuration(seconds = offset)

  proc zonedTimeFromTime(time: Time): ZonedTime {.locks: 0.}=
    result.isDst = false
    result.utcOffset = offset
    result.time = time

  newTimezone("", zonedTimeFromTime, zonedTImeFromAdjTime)

template parseTest(s, f, sExpected: string, ydExpected: int) =
  let
    parsed = s.parse(f, utc())
    parsedStr = $parsed
  check parsedStr == sExpected
  check parsed.yearday == ydExpected

template parseTestExcp(s, f: string) =
  expect ValueError:
    let parsed = s.parse(f)

template parseTestTimeOnly(s, f, sExpected: string) =
  check sExpected in $s.parse(f, utc())

# because setting a specific timezone for testing is platform-specific, we use
# explicit timezone offsets in all tests.
template runTimezoneTests() =
  parseTest("Tuesday at 09:04am on Dec 15, 2015 +0",
      "dddd 'at' hh:mmtt 'on' MMM d, yyyy z", "2015-12-15T09:04:00Z", 348)
  # ANSIC       = "Mon Jan _2 15:04:05 2006"
  parseTest("Thu Jan 12 15:04:05 2006 +0", "ddd MMM dd HH:mm:ss yyyy z",
      "2006-01-12T15:04:05Z", 11)
  # UnixDate    = "Mon Jan _2 15:04:05 MST 2006"
  parseTest("Thu Jan 12 15:04:05 2006 +0", "ddd MMM dd HH:mm:ss yyyy z",
      "2006-01-12T15:04:05Z", 11)
  # RubyDate    = "Mon Jan 02 15:04:05 -0700 2006"
  parseTest("Mon Feb 29 15:04:05 -07:00 2016 +0", "ddd MMM dd HH:mm:ss zzz yyyy z",
      "2016-02-29T15:04:05Z", 59) # leap day
  # RFC822      = "02 Jan 06 15:04 MST"
  parseTest("12 Jan 16 15:04 +0", "dd MMM yy HH:mm z",
      "2016-01-12T15:04:00Z", 11)
  # RFC822Z     = "02 Jan 06 15:04 -0700" # RFC822 with numeric zone
  parseTest("01 Mar 16 15:04 -07:00", "dd MMM yy HH:mm zzz",
      "2016-03-01T22:04:00Z", 60) # day after february in leap year
  # RFC850      = "Monday, 02-Jan-06 15:04:05 MST"
  parseTest("Monday, 12-Jan-06 15:04:05 +0", "dddd, dd-MMM-yy HH:mm:ss z",
      "2006-01-12T15:04:05Z", 11)
  # RFC1123     = "Mon, 02 Jan 2006 15:04:05 MST"
  parseTest("Sun, 01 Mar 2015 15:04:05 +0", "ddd, dd MMM yyyy HH:mm:ss z",
      "2015-03-01T15:04:05Z", 59) # day after february in non-leap year
  # RFC1123Z    = "Mon, 02 Jan 2006 15:04:05 -0700" # RFC1123 with numeric zone
  parseTest("Thu, 12 Jan 2006 15:04:05 -07:00", "ddd, dd MMM yyyy HH:mm:ss zzz",
      "2006-01-12T22:04:05Z", 11)
  # RFC3339     = "2006-01-02T15:04:05Z07:00"
  parseTest("2006-01-12T15:04:05Z-07:00", "yyyy-MM-dd'T'HH:mm:ss'Z'zzz",
      "2006-01-12T22:04:05Z", 11)
  # RFC3339Nano = "2006-01-02T15:04:05.999999999Z07:00"
  parseTest("2006-01-12T15:04:05.999999999Z-07:00",
      "yyyy-MM-dd'T'HH:mm:ss'.999999999Z'zzz", "2006-01-12T22:04:05Z", 11)
  for tzFormat in ["z", "zz", "zzz"]:
    # formatting timezone as 'Z' for UTC
    parseTest("2001-01-12T22:04:05Z", "yyyy-MM-dd'T'HH:mm:ss" & tzFormat,
        "2001-01-12T22:04:05Z", 11)
  # timezone offset formats
  parseTest("2001-01-12T15:04:05 +7", "yyyy-MM-dd'T'HH:mm:ss z",
      "2001-01-12T08:04:05Z", 11)
  parseTest("2001-01-12T15:04:05 +07", "yyyy-MM-dd'T'HH:mm:ss zz",
      "2001-01-12T08:04:05Z", 11)
  parseTest("2001-01-12T15:04:05 +07:00", "yyyy-MM-dd'T'HH:mm:ss zzz",
      "2001-01-12T08:04:05Z", 11)
  parseTest("2001-01-12T15:04:05 +07:30:59", "yyyy-MM-dd'T'HH:mm:ss zzzz",
      "2001-01-12T07:33:06Z", 11)
  # Kitchen     = "3:04PM"
  parseTestTimeOnly("3:04PM", "h:mmtt", "15:04:00")

  # Bug with parse not setting DST properly if the current local DST differs from
  # the date being parsed. Need to test parse dates both in and out of DST. We
  # are testing that be relying on the fact that tranforming a TimeInfo to a Time
  # and back again will correctly set the DST value. With the incorrect parse
  # behavior this will introduce a one hour offset from the named time and the
  # parsed time if the DST value differs between the current time and the date we
  # are parsing.
  let dstT1 = parse("2016-01-01 00:00:00", "yyyy-MM-dd HH:mm:ss")
  let dstT2 = parse("2016-06-01 00:00:00", "yyyy-MM-dd HH:mm:ss")
  check dstT1 == toTime(dstT1).local
  check dstT2 == toTime(dstT2).local

  block dstTest:
    # parsing will set isDST in relation to the local time. We take a date in
    # January and one in July to maximize the probability to hit one date with DST
    # and one without on the local machine. However, this is not guaranteed.
    let
      parsedJan = parse("2016-01-05 04:00:00+01:00", "yyyy-MM-dd HH:mm:sszzz")
      parsedJul = parse("2016-07-01 04:00:00+01:00", "yyyy-MM-dd HH:mm:sszzz")
    check toTime(parsedJan).toUnix == 1451962800
    check toTime(parsedJul).toUnix == 1467342000

template usingTimezone(tz: string, body: untyped) =
  when defined(linux) or defined(macosx):
    let oldZone = getEnv("TZ")
    putEnv("TZ", tz)
    body
    putEnv("TZ", oldZone)

suite "ttimes":

  # Generate tests for multiple timezone files where available
  # Set the TZ env var for each test
  when defined(linux) or defined(macosx):
    let tz_dir = getEnv("TZDIR", "/usr/share/zoneinfo")
    const f = "yyyy-MM-dd HH:mm zzz"

    var tz_cnt = 0
    for timezone in walkFiles(tz_dir & "/**/*"):
      if symlinkExists(timezone) or timezone.endsWith(".tab") or
          timezone.endsWith(".list"):
        continue

      usingTimezone(timezone):
        test "test for " & timezone:
          tz_cnt.inc
          runTimezoneTests()

    test "enough timezone files tested":
      check tz_cnt > 10

  else:
    # not on Linux or macosx: run in the local timezone only
    test "parseTest":
      runTimezoneTests()

  test "dst handling":
    usingTimezone("Europe/Stockholm"):
      # In case of an impossible time, the time is moved to after the
      # impossible time period
      check initDateTime(26, mMar, 2017, 02, 30, 00).format(f) ==
        "2017-03-26 03:30 +02:00"
      # In case of an ambiguous time, the earlier time is choosen
      check initDateTime(29, mOct, 2017, 02, 00, 00).format(f) ==
        "2017-10-29 02:00 +02:00"
      # These are just dates on either side of the dst switch
      check initDateTime(29, mOct, 2017, 01, 00, 00).format(f) ==
        "2017-10-29 01:00 +02:00"
      check initDateTime(29, mOct, 2017, 01, 00, 00).isDst
      check initDateTime(29, mOct, 2017, 03, 01, 00).format(f) ==
        "2017-10-29 03:01 +01:00"
      check (not initDateTime(29, mOct, 2017, 03, 01, 00).isDst)

      check initDateTime(21, mOct, 2017, 01, 00, 00).format(f) ==
        "2017-10-21 01:00 +02:00"

  test "issue #6520":
    usingTimezone("Europe/Stockholm"):
      var local = fromUnix(1469275200).local
      var utc = fromUnix(1469275200).utc

      let claimedOffset = initDuration(seconds = local.utcOffset)
      local.utcOffset = 0
      check claimedOffset == utc.toTime - local.toTime

  test "issue #5704":
    usingTimezone("Asia/Seoul"):
      let diff = parse("19700101-000000", "yyyyMMdd-hhmmss").toTime -
        parse("19000101-000000", "yyyyMMdd-hhmmss").toTime
      check diff == initDuration(seconds = 2208986872)

  test "issue #6465":
    usingTimezone("Europe/Stockholm"):
      let dt = parse("2017-03-25 12:00", "yyyy-MM-dd hh:mm")
      check $(dt + initTimeInterval(days = 1)) == "2017-03-26T12:00:00+02:00"
      check $(dt + initDuration(days = 1)) == "2017-03-26T13:00:00+02:00"

  test "adding/subtracting time across dst":
    usingTimezone("Europe/Stockholm"):
      let dt1 = initDateTime(26, mMar, 2017, 03, 00, 00)
      check $(dt1 - 1.seconds) == "2017-03-26T01:59:59+01:00"

      var dt2 = initDateTime(29, mOct, 2017, 02, 59, 59)
      check  $(dt2 + 1.seconds) == "2017-10-29T02:00:00+01:00"

  test "datetime before epoch":
    check $fromUnix(-2147483648).utc == "1901-12-13T20:45:52Z"

  test "incorrect inputs: empty string":
    parseTestExcp("", "yyyy-MM-dd")

  test "incorrect inputs: year":
    parseTestExcp("20-02-19", "yyyy-MM-dd")

  test "incorrect inputs: month number":
    parseTestExcp("2018-2-19", "yyyy-MM-dd")

  test "incorrect inputs: month name":
    parseTestExcp("2018-Fe", "yyyy-MMM-dd")

  test "incorrect inputs: day":
    parseTestExcp("2018-02-1", "yyyy-MM-dd")

  test "incorrect inputs: day of week":
    parseTestExcp("2018-Feb-Mo", "yyyy-MMM-ddd")

  test "incorrect inputs: hour":
    parseTestExcp("2018-02-19 1:30", "yyyy-MM-dd hh:mm")

  test "incorrect inputs: minute":
    parseTestExcp("2018-02-19 16:3", "yyyy-MM-dd hh:mm")

  test "incorrect inputs: second":
    parseTestExcp("2018-02-19 16:30:0", "yyyy-MM-dd hh:mm:ss")

  test "incorrect inputs: timezone (z)":
    parseTestExcp("2018-02-19 16:30:00 ", "yyyy-MM-dd hh:mm:ss z")

  test "incorrect inputs: timezone (zz) 1":
    parseTestExcp("2018-02-19 16:30:00 ", "yyyy-MM-dd hh:mm:ss zz")

  test "incorrect inputs: timezone (zz) 2":
    parseTestExcp("2018-02-19 16:30:00 +1", "yyyy-MM-dd hh:mm:ss zz")

  test "incorrect inputs: timezone (zzz) 1":
    parseTestExcp("2018-02-19 16:30:00 ", "yyyy-MM-dd hh:mm:ss zzz")

  test "incorrect inputs: timezone (zzz) 2":
    parseTestExcp("2018-02-19 16:30:00 +01:", "yyyy-MM-dd hh:mm:ss zzz")

  test "incorrect inputs: timezone (zzz) 3":
    parseTestExcp("2018-02-19 16:30:00 +01:0", "yyyy-MM-dd hh:mm:ss zzz")

  test "incorrect inputs: year (yyyy/uuuu)":
    parseTestExcp("-0001", "yyyy")
    parseTestExcp("-0001", "YYYY")
    parseTestExcp("1", "yyyy")
    parseTestExcp("12345", "yyyy")
    parseTestExcp("1", "uuuu")
    parseTestExcp("12345", "uuuu")
    parseTestExcp("-1 BC", "UUUU g")

  test "incorrect inputs: invalid sign":
    parseTestExcp("+1", "YYYY")
    parseTestExcp("+1", "dd")
    parseTestExcp("+1", "MM")
    parseTestExcp("+1", "hh")
    parseTestExcp("+1", "mm")
    parseTestExcp("+1", "ss")

  test "_ as a separator":
    discard parse("2000_01_01", "YYYY'_'MM'_'dd")

  test "dynamic timezone":
    let tz = staticTz(seconds = -9000)
    let dt = initDateTime(1, mJan, 2000, 12, 00, 00, tz)
    check dt.utcOffset == -9000
    check dt.isDst == false
    check $dt == "2000-01-01T12:00:00+02:30"
    check $dt.utc == "2000-01-01T09:30:00Z"
    check $dt.utc.inZone(tz) == $dt

  test "isLeapYear":
    check isLeapYear(2016)
    check (not isLeapYear(2015))
    check isLeapYear(2000)
    check (not isLeapYear(1900))

  test "TimeInterval":
    let t = fromUnix(876124714).utc # Mon 6 Oct 08:58:34 BST 1997
    # Interval tests
    let t2 = t - 2.years
    check t2.year == 1995
    let t3 = (t - 7.years - 34.minutes - 24.seconds)
    check t3.year == 1990
    check t3.minute == 24
    check t3.second == 10
    check (t + 1.hours).toTime.toUnix == t.toTime.toUnix + 60 * 60
    check (t - 1.hours).toTime.toUnix == t.toTime.toUnix - 60 * 60

  test "TimeInterval - months":
    var dt = initDateTime(1, mFeb, 2017, 00, 00, 00, utc())
    check $(dt - initTimeInterval(months = 1)) == "2017-01-01T00:00:00Z"
    dt = initDateTime(15, mMar, 2017, 00, 00, 00, utc())
    check $(dt - initTimeInterval(months = 1)) == "2017-02-15T00:00:00Z"
    dt = initDateTime(31, mMar, 2017, 00, 00, 00, utc())
    # This happens due to monthday overflow. It's consistent with Phobos.
    check $(dt - initTimeInterval(months = 1)) == "2017-03-03T00:00:00Z"

  test "duration":
    let d = initDuration
    check d(hours = 48) + d(days = 5) == d(weeks = 1)
    let dt = initDateTime(01, mFeb, 2000, 00, 00, 00, 0, utc()) + d(milliseconds = 1)
    check dt.nanosecond == convert(Milliseconds, Nanoseconds, 1)
    check d(seconds = 1, milliseconds = 500) * 2 == d(seconds = 3)
    check d(seconds = 3) div 2 == d(seconds = 1, milliseconds = 500)
    check d(milliseconds = 1001).seconds == 1
    check d(seconds = 1, milliseconds = 500) - d(milliseconds = 1250) ==
      d(milliseconds = 250)
    check d(seconds = 1, milliseconds = 1) < d(seconds = 1, milliseconds = 2)
    check d(seconds = 1) <= d(seconds = 1)
    check d(seconds = 0) - d(milliseconds = 1500) == d(milliseconds = -1500)
    check d(milliseconds = -1500) == d(seconds = -1, milliseconds = -500)
    check d(seconds = -1, milliseconds = 500) == d(milliseconds = -500)
    check initDuration(seconds = 1, nanoseconds = 2) <=
      initDuration(seconds = 1, nanoseconds = 3)
    check (initDuration(seconds = 1, nanoseconds = 3) <=
      initDuration(seconds = 1, nanoseconds = 1)).not

  test "large/small dates":
    discard initDateTime(1, mJan, -35_000, 12, 00, 00, utc())
    # with local tz
    discard initDateTime(1, mJan, -35_000, 12, 00, 00)
    discard initDateTime(1, mJan,  35_000, 12, 00, 00)
    # with duration/timeinterval
    let dt = initDateTime(1, mJan, -35_000, 12, 00, 00, utc()) +
      initDuration(seconds = 1)
    check dt.second == 1
    let dt2 = dt + 35_001.years
    check $dt2 == "0001-01-01T12:00:01Z"

  test "compare datetimes":
    var dt1 = now()
    var dt2 = dt1
    check dt1 == dt2
    check dt1 <= dt2
    dt2 = dt2 + 1.seconds
    check dt1 < dt2

  test "adding/subtracting TimeInterval":
    # add/subtract TimeIntervals and Time/TimeInfo
    let now = getTime().utc
    check now + convert(Seconds, Nanoseconds, 1).nanoseconds == now + 1.seconds
    check now + 1.weeks == now + 7.days
    check now - 1.seconds == now - 3.seconds + 2.seconds
    check now + 65.seconds == now + 1.minutes + 5.seconds
    check now + 60.minutes == now + 1.hours
    check now + 24.hours == now + 1.days
    check now + 13.months == now + 1.years + 1.months
    check toUnix(fromUnix(0) + 2.seconds) == 2
    check toUnix(fromUnix(0) - 2.seconds) == -2
    var ti1 = now + 1.years
    ti1 = ti1 - 1.years
    check ti1 == now
    ti1 = ti1 + 1.days
    check ti1 == now + 1.days

    # Bug with adding a day to a Time
    let day = 24.hours
    let tomorrow = now + day
    check tomorrow - now == initDuration(days = 1)

  # Disabled for JS because it fails due to precision errors
  # (The JS target uses float64 for int64).
  when not defined(js):
    test "fromWinTime/toWinTime":
      check 0.fromUnix.toWinTime.fromWinTime.toUnix == 0
      check (-1).fromWinTime.nanosecond == convert(Seconds, Nanoseconds, 1) - 100
      check (-1).fromWinTime.toWinTime == -1
      # One nanosecond is discarded due to differences in time resolution
      check initTime(0, 101).toWinTime.fromWinTime.nanosecond == 100
      check initTime(0, 101).toWinTime.fromWinTime.nanosecond == 100

  test "issue 7620":
    let layout = "M/d/yyyy' 'h:mm:ss' 'tt' 'z"
    let t7620_am = parse("4/15/2017 12:01:02 AM +0", layout, utc())
    check t7620_am.format(layout) == "4/15/2017 12:01:02 AM Z"
    let t7620_pm = parse("4/15/2017 12:01:02 PM +0", layout, utc())
    check t7620_pm.format(layout) == "4/15/2017 12:01:02 PM Z"

  test "format":
    var dt = initDateTime(1, mJan, -0001,
                          17, 01, 02, 123_456_789,
                          staticTz(hours = 1, minutes = 2, seconds = 3))
    check dt.format("d") == "1"
    check dt.format("dd") == "01"
    check dt.format("ddd") == "Fri"
    check dt.format("dddd") == "Friday"
    check dt.format("h") == "5"
    check dt.format("hh") == "05"
    check dt.format("H") == "17"
    check dt.format("HH") == "17"
    check dt.format("m") == "1"
    check dt.format("mm") == "01"
    check dt.format("M") == "1"
    check dt.format("MM") == "01"
    check dt.format("MMM") == "Jan"
    check dt.format("MMMM") == "January"
    check dt.format("s") == "2"
    check dt.format("ss") == "02"
    check dt.format("t") == "P"
    check dt.format("tt") == "PM"
    check dt.format("yy") == "02"
    check dt.format("yyyy") == "0002"
    check dt.format("YYYY") == "2"
    check dt.format("uuuu") == "-0001"
    check dt.format("UUUU") == "-1"
    check dt.format("z") == "-1"
    check dt.format("zz") == "-01"
    check dt.format("zzz") == "-01:02"
    check dt.format("zzzz") == "-01:02:03"
    check dt.format("g") == "BC"

    check dt.format("fff") == "123"
    check dt.format("ffffff") == "123456"
    check dt.format("fffffffff") == "123456789"
    dt.nanosecond = 1
    check dt.format("fff") == "000"
    check dt.format("ffffff") == "000000"
    check dt.format("fffffffff") == "000000001"

    dt.year = 12345
    check dt.format("yyyy") == "+12345"
    check dt.format("uuuu") == "+12345"
    dt.year = -12345
    check dt.format("yyyy") == "+12346"
    check dt.format("uuuu") == "-12345"

    expect ValueError:
      discard initTimeFormat("'")

    expect ValueError:
      discard initTimeFormat("'foo")

    expect ValueError:
      discard initTimeFormat("foo'")

    for tz in [
        (staticTz(seconds = 0), "+0", "+00", "+00:00"), # UTC
        (staticTz(seconds = -3600), "+1", "+01", "+01:00"), # CET
        (staticTz(seconds = -39600), "+11", "+11", "+11:00"), # two digits
        (staticTz(seconds = -1800), "+0", "+00", "+00:30"), # half an hour
        (staticTz(seconds = 7200), "-2", "-02", "-02:00"), # positive
        (staticTz(seconds = 38700), "-10", "-10", "-10:45")]: # positive with three quaters hour
      let dt = initDateTime(1, mJan, 2000, 00, 00, 00, tz[0])
      doAssert dt.format("z") == tz[1]
      doAssert dt.format("zz") == tz[2]
      doAssert dt.format("zzz") == tz[3]

  test "parse":
    check $parse("20180101", "yyyyMMdd", utc()) == "2018-01-01T00:00:00Z"
    parseTestExcp("+120180101", "yyyyMMdd")

    check parse("1", "YYYY", utc()).year == 1
    check parse("1 BC", "YYYY g", utc()).year == 0
    check parse("0001 BC", "yyyy g", utc()).year == 0
    check parse("+12345 BC", "yyyy g", utc()).year == -12344
    check parse("1 AD", "YYYY g", utc()).year == 1
    check parse("0001 AD", "yyyy g", utc()).year == 1
    check parse("+12345 AD", "yyyy g", utc()).year == 12345

    check parse("-1", "UUUU", utc()).year == -1
    check parse("-0001", "uuuu", utc()).year == -1

    discard parse("foobar", "'foobar'")
    discard parse("foo'bar", "'foo''''bar'")
    discard parse("'", "''")

    parseTestExcp("2000 A", "yyyy g")

  test "countLeapYears":
    # 1920, 2004 and 2020 are leap years, and should be counted starting at the following year
    check countLeapYears(1920) + 1 == countLeapYears(1921)
    check countLeapYears(2004) + 1 == countLeapYears(2005)
    check countLeapYears(2020) + 1 == countLeapYears(2021)

  test "timezoneConversion":
    var l = now()
    let u = l.utc
    l = u.local

    check l.timezone == local()
    check u.timezone == utc()

  test "getDayOfWeek":
    check getDayOfWeek(01, mJan, 0000) == dSat
    check getDayOfWeek(01, mJan, -0023) == dSat
    check getDayOfWeek(21, mSep, 1900) == dFri
    check getDayOfWeek(01, mJan, 1970) == dThu
    check getDayOfWeek(21, mSep, 1970) == dMon
    check getDayOfWeek(01, mJan, 2000) == dSat
    check getDayOfWeek(01, mJan, 2021) == dFri

  test "between - simple":
    let x = initDateTime(10, mJan, 2018, 13, 00, 00)
    let y = initDateTime(11, mJan, 2018, 12, 00, 00)
    doAssert x + between(x, y) == y

  test "between - dst start":
    usingTimezone("Europe/Stockholm"):
      let x = initDateTime(25, mMar, 2018, 00, 00, 00)
      let y = initDateTime(25, mMar, 2018, 04, 00, 00)
      doAssert x + between(x, y) == y

  test "between - empty interval":
    let x = now()
    let y = x
    doAssert x + between(x, y) == y

  test "between - dst end":
    usingTimezone("Europe/Stockholm"):
      let x = initDateTime(27, mOct, 2018, 02, 00, 00)
      let y = initDateTime(28, mOct, 2018, 01, 00, 00)
      doAssert x + between(x, y) == y

  test "between - long day":
    usingTimezone("Europe/Stockholm"):
      # This day is 25 hours long in Europe/Stockholm
      let x = initDateTime(28, mOct, 2018, 00, 30, 00)
      let y = initDateTime(29, mOct, 2018, 00, 00, 00)
      doAssert between(x, y) == 24.hours + 30.minutes
      doAssert x + between(x, y) == y

  test "between - offset change edge case":
    # This test case is important because in this case
    # `x + between(x.utc, y.utc) == y` is not true, which is very rare.
    usingTimezone("America/Belem"):
      let x = initDateTime(24, mOct, 1987, 00, 00, 00)
      let y = initDateTime(26, mOct, 1987, 23, 00, 00)
      doAssert x + between(x, y) == y
      doAssert y + between(y, x) == x

  test "between - all units":
    let x = initDateTime(1, mJan, 2000, 00, 00, 00, utc())
    let ti = initTimeInterval(1, 1, 1, 1, 1, 1, 1, 1, 1, 1)
    let y = x + ti
    doAssert between(x, y) == ti
    doAssert between(y, x) == -ti

  test "between - monthday overflow":
      let x = initDateTime(31, mJan, 2001, 00, 00, 00, utc())
      let y = initDateTime(1, mMar, 2001, 00, 00, 00, utc())
      doAssert x + between(x, y) == y

  test "between - misc":
    block:
      let x = initDateTime(31, mDec, 2000, 12, 00, 00, utc())
      let y = initDateTime(01, mJan, 2001, 00, 00, 00, utc())
      doAssert between(x, y) == 12.hours

    block:
      let x = initDateTime(31, mDec, 2000, 12, 00, 00, utc())
      let y = initDateTime(02, mJan, 2001, 00, 00, 00, utc())
      doAssert between(x, y) == 1.days + 12.hours

    block:
      let x = initDateTime(31, mDec, 1995, 00, 00, 00, utc())
      let y = initDateTime(01, mFeb, 2000, 00, 00, 00, utc())
      doAssert x + between(x, y) == y

    block:
      let x = initDateTime(01, mDec, 1995, 00, 00, 00, utc())
      let y = initDateTime(31, mJan, 2000, 00, 00, 00, utc())
      doAssert x + between(x, y) == y

    block:
      let x = initDateTime(31, mJan, 2000, 00, 00, 00, utc())
      let y = initDateTime(01, mFeb, 2000, 00, 00, 00, utc())
      doAssert x + between(x, y) == y

    block:
      let x = initDateTime(01, mJan, 1995, 12, 00, 00, utc())
      let y = initDateTime(01, mFeb, 1995, 00, 00, 00, utc())
      doAssert between(x, y) == 4.weeks + 2.days + 12.hours

    block:
      let x = initDateTime(31, mJan, 1995, 00, 00, 00, utc())
      let y = initDateTime(10, mFeb, 1995, 00, 00, 00, utc())
      doAssert x + between(x, y) == y

    block:
      let x = initDateTime(31, mJan, 1995, 00, 00, 00, utc())
      let y = initDateTime(10, mMar, 1995, 00, 00, 00, utc())
      doAssert x + between(x, y) == y
      doAssert between(x, y) == 1.months + 1.weeks

  test "inX procs":
    doAssert initDuration(seconds = 1).inSeconds == 1
    doAssert initDuration(seconds = -1).inSeconds == -1
    doAssert initDuration(seconds = -1, nanoseconds = 1).inSeconds == 0
    doAssert initDuration(nanoseconds = -1).inSeconds == 0
    doAssert initDuration(milliseconds = 500).inMilliseconds == 500
    doAssert initDuration(milliseconds = -500).inMilliseconds == -500
    doAssert initDuration(nanoseconds = -999999999).inMilliseconds == -999
