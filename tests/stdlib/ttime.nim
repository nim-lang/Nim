# test the new time module
discard """
  file: "ttime.nim"
"""

import
  times, strutils

doAssert( $getTime() == getLocalTime(getTime()).format("ddd MMM dd HH:mm:ss yyyy"))
# $ date --date='@2147483647'
# Tue 19 Jan 03:14:07 GMT 2038

var t = getGMTime(fromSeconds(2147483647))
doAssert t.format("ddd dd MMM hh:mm:ss ZZZ yyyy") == "Tue 19 Jan 03:14:07 UTC 2038"
doAssert t.format("ddd ddMMMhh:mm:ssZZZyyyy") == "Tue 19Jan03:14:07UTC2038"

doAssert t.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
  " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
  "19 19 Tue Tuesday 3 03 3 03 14 14 1 01 Jan January 7 07 A AM 8 38 038 2038 02038 0 00 00:00 UTC"

doAssert t.format("yyyyMMddhhmmss") == "20380119031407"

var t2 = getGMTime(fromSeconds(160070789)) # Mon 27 Jan 16:06:29 GMT 1975
doAssert t2.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
  " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
  "27 27 Mon Monday 4 04 16 16 6 06 1 01 Jan January 29 29 P PM 5 75 975 1975 01975 0 00 00:00 UTC"

when not defined(JS):
  when sizeof(Time) == 8:
    var t3 = getGMTime(fromSeconds(889067643645)) # Fri  7 Jun 19:20:45 BST 30143
    doAssert t3.format("d dd ddd dddd h hh H HH m mm M MM MMM MMMM s" &
      " ss t tt y yy yyy yyyy yyyyy z zz zzz ZZZ") ==
      "7 07 Fri Friday 6 06 18 18 20 20 6 06 Jun June 45 45 P PM 3 43 143 0143 30143 0 00 00:00 UTC"
    doAssert t3.format(":,[]()-/") == ":,[]()-/"

var t4 = getGMTime(fromSeconds(876124714)) # Mon  6 Oct 08:58:34 BST 1997
doAssert t4.format("M MM MMM MMMM") == "10 10 Oct October"

# Interval tests
doAssert((t4 - initInterval(years = 2)).format("yyyy") == "1995")
doAssert((t4 - initInterval(years = 7, minutes = 34, seconds = 24)).format("yyyy mm ss") == "1990 24 10")

var s = "Tuesday at 09:04am on Dec 15, 2015"
var f = "dddd at hh:mmtt on MMM d, yyyy"
doAssert($s.parse(f) == "Tue Dec 15 09:04:00 2015")
# ANSIC       = "Mon Jan _2 15:04:05 2006"
s = "Thu Jan 12 15:04:05 2006"
f = "ddd MMM dd HH:mm:ss yyyy"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# UnixDate    = "Mon Jan _2 15:04:05 MST 2006"
s = "Thu Jan 12 15:04:05 MST 2006"
f = "ddd MMM dd HH:mm:ss ZZZ yyyy"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# RubyDate    = "Mon Jan 02 15:04:05 -0700 2006"
s = "Thu Jan 12 15:04:05 -07:00 2006"
f = "ddd MMM dd HH:mm:ss zzz yyyy"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# RFC822      = "02 Jan 06 15:04 MST"
s = "12 Jan 16 15:04 MST"
f = "dd MMM yy HH:mm ZZZ"
doAssert($s.parse(f) == "Tue Jan 12 15:04:00 2016")
# RFC822Z     = "02 Jan 06 15:04 -0700" # RFC822 with numeric zone
s = "12 Jan 16 15:04 -07:00"
f = "dd MMM yy HH:mm zzz"
doAssert($s.parse(f) == "Tue Jan 12 15:04:00 2016")
# RFC850      = "Monday, 02-Jan-06 15:04:05 MST"
s = "Monday, 12-Jan-06 15:04:05 MST"
f = "dddd, dd-MMM-yy HH:mm:ss ZZZ"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# RFC1123     = "Mon, 02 Jan 2006 15:04:05 MST"
s = "Thu, 12 Jan 2006 15:04:05 MST"
f = "ddd, dd MMM yyyy HH:mm:ss ZZZ"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# RFC1123Z    = "Mon, 02 Jan 2006 15:04:05 -0700" # RFC1123 with numeric zone
s = "Thu, 12 Jan 2006 15:04:05 -07:00"
f = "ddd, dd MMM yyyy HH:mm:ss zzz"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# RFC3339     = "2006-01-02T15:04:05Z07:00"
s = "2006-01-12T15:04:05Z-07:00"
f = "yyyy-MM-ddTHH:mm:ssZzzz"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
f = "yyyy-MM-dd'T'HH:mm:ss'Z'zzz"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# RFC3339Nano = "2006-01-02T15:04:05.999999999Z07:00"
s = "2006-01-12T15:04:05.999999999Z-07:00"
f = "yyyy-MM-ddTHH:mm:ss.999999999Zzzz"
doAssert($s.parse(f) == "Thu Jan 12 15:04:05 2006")
# Kitchen     = "3:04PM"
s = "3:04PM"
f = "h:mmtt"
doAssert "15:04:00" in $s.parse(f)
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

# toSeconds tests with GM and Local timezones
#var t4 = getGMTime(fromSeconds(876124714)) # Mon  6 Oct 08:58:34 BST 1997
var t4L = getLocalTime(fromSeconds(876124714))
doAssert toSeconds(timeInfoToTime(t4L)) == 876124714    # fromSeconds is effectively "localTime"
doAssert toSeconds(timeInfoToTime(t4L)) + t4L.timezone.float == toSeconds(timeInfoToTime(t4))

# adding intervals
var
  a1L = toSeconds(timeInfoToTime(t4L + initInterval(hours = 1))) + t4L.timezone.float
  a1G = toSeconds(timeInfoToTime(t4)) + 60.0 * 60.0
doAssert a1L == a1G

# subtracting intervals
a1L = toSeconds(timeInfoToTime(t4L - initInterval(hours = 1))) + t4L.timezone.float
a1G = toSeconds(timeInfoToTime(t4)) - (60.0 * 60.0)
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
