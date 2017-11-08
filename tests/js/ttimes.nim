discard """
  action: run
"""

import times

# $ date --date='@2147483647'
# Tue 19 Jan 03:14:07 GMT 2038

block yeardayTest:
  doAssert fromSeconds(2147483647).utc.yearday == 18

block localTime:
  var local = now()
  let utc = local.utc
  doAssert local.toTime.toSeconds == utc.toTime.toSeconds
