discard """
  action: run
"""

import times

# $ date --date='@2147483647'
# Tue 19 Jan 03:14:07 GMT 2038

block yeardayTest:
  doAssert fromUnix(2147483647).utc.yearday == 18

block localTime:
  var local = now()
  let utc = local.utc
  doAssert local.toTime == utc.toTime

let a = fromUnix(1_000_000_000)
let b = fromUnix(1_500_000_000)
doAssert b - a == initDuration(seconds = 500_000_000)

# Because we can't change the timezone JS uses, we define a simple static timezone for testing.

proc staticZoneInfoFromUtc(time: Time): ZonedTime =
  result.utcOffset = -7200
  result.isDst = false
  result.adjTime = time + 7200.seconds

proc staticZoneInfoFromTz(adjTime: Time): ZonedTIme =
  result.utcOffset = -7200
  result.isDst = false
  result.adjTime = adjTime

let utcPlus2 = Timezone(zoneInfoFromUtc: staticZoneInfoFromUtc, zoneInfoFromTz: staticZoneInfoFromTz, name: "")

block timezoneTests:
  let dt = initDateTime(01, mJan, 2017, 12, 00, 00, utcPlus2)
  doAssert $dt == "2017-01-01T12:00:00+02:00"
  doAssert $dt.utc == "2017-01-01T10:00:00+00:00"
  doAssert $dt.utc.inZone(utcPlus2) == $dt

doAssert $initDateTime(01, mJan, 1911, 12, 00, 00, utc()) == "1911-01-01T12:00:00+00:00"
doAssert $initDateTime(01, mJan, 0023, 12, 00, 00, utc()) == "0023-01-01T12:00:00+00:00"