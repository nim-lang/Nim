# test times module with js
discard """
  action: run
"""

import times

# $ date --date='@2147483647'
# Tue 19 Jan 03:14:07 GMT 2038

block yeardayTest:
  # check if yearday attribute is properly set on TimeInfo creation
  doAssert fromSeconds(2147483647).getGMTime().yearday == 18

block localTimezoneTest:
  # check if timezone is properly set during Time to TimeInfo conversion
  doAssert fromSeconds(2147483647).getLocalTime().timezone == getTimezone()

block timestampPersistenceTest:
  # check if timestamp persists during TimeInfo to Time conversion
  const
    timeString = "2017-03-21T12:34:56+03:00"
    timeStringGmt = "2017-03-21T09:34:56+00:00"
    fmt = "yyyy-MM-dd'T'HH:mm:sszzz"

  doAssert $timeString.parse(fmt).toTime().getGMTime() == timeStringGmt
