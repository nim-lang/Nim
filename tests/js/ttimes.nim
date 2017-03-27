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

block timezoneTest:
  # check if timezone is properly set durint Time to TimeInfo conversion
  doAssert fromSeconds(2147483647).getLocalTime().timezone == getTimezone()
