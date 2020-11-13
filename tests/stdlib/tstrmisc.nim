discard """
  action: "run"
"""

import strmisc


func main() =
  doAssert parseFloatThousandSep("0") == 0.0
  doAssert parseFloatThousandSep("-0") == -0.0
  doAssert parseFloatThousandSep("0.0") == 0.0
  doAssert parseFloatThousandSep("1.0") == 1.0
  doAssert parseFloatThousandSep("-0.0") == -0.0
  doAssert parseFloatThousandSep("-1.0") == -1.0
  doAssert parseFloatThousandSep("1.000") == 1.0
  doAssert parseFloatThousandSep("-1.000") == -1.0


main()
static: main()
