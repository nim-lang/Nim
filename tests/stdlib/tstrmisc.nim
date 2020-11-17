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

  doAssert parseFloatThousandSep("1,111") == 1111.0
  doAssertRaises(ValueError): discard parseFloatThousandSep("1,11")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1,1")

  doAssertRaises(ValueError): discard parseFloatThousandSep("1,0000.000")
  doAssertRaises(ValueError): discard parseFloatThousandSep("--")
  doAssertRaises(ValueError): discard parseFloatThousandSep("..")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1,,000")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1..000")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1,000000")

  doAssertRaises(ValueError): discard parseFloatThousandSep(",1")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1,")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1.")
  doAssertRaises(ValueError): discard parseFloatThousandSep(".1")


main()
static: main()
