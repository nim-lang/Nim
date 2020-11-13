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
  doAssertRaises(ValueError):
    discard parseFloatThousandSep("1,0000.000")
    discard parseFloatThousandSep("--")
    discard parseFloatThousandSep("..")
    discard parseFloatThousandSep("000,1.000,,,,,,,,,,,,,,000,,,,,0000")
    discard parseFloatThousandSep("000.1,000..............000.....0000")


main()
static: main()
