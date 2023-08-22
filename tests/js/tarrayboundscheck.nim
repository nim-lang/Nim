discard """
  output: '''idx out of bounds: -1
month out of bounds: 0
Jan
Feb
Mar
Apr
May
Jun
Jul
Aug
Sep
Oct
Nov
Dec
month out of bounds: 13
idx out of bounds: 14
'''
"""

{.push boundChecks:on.}

# see issue #6532:
# js backend 0.17.3: array bounds check for non zero based arrays is buggy

proc test_arrayboundscheck() =
  var months: array[1..12, string] =
    ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

  var indices = [0,1,2,3,4,5,6,7,8,9,10,11,12,13]

  for i in -1 .. 14:
    try:
      let idx = indices[i]
      try:
        echo months[idx]
      except:
        echo "month out of bounds: ", idx
    except:
      echo "idx out of bounds: ", i
  
  # #13966
  var negativeIndexed: array[-2..2, int] = [0, 1, 2, 3, 4]
  negativeIndexed[-1] = 2
  negativeIndexed[1] = 2
  doAssert negativeIndexed == [0, 2, 2, 2, 4]

test_arrayboundscheck()
{.pop.}