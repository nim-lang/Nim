import strmisc


func main() =
  block:
    doAssert parseFloatThousandSep("0") == 0.0
    doAssert parseFloatThousandSep("-0") == -0.0
    doAssert parseFloatThousandSep("0.0") == 0.0
    doAssert parseFloatThousandSep("1.0") == 1.0
    doAssert parseFloatThousandSep("-0.0") == -0.0
    doAssert parseFloatThousandSep("-1.0") == -1.0
    doAssert parseFloatThousandSep("1.000") == 1.0
    doAssert parseFloatThousandSep("-1.000") == -1.0
    doAssertRaises(ValueError): discard parseFloatThousandSep("1,0000.000")
    doAssertRaises(ValueError): discard parseFloatThousandSep("--")
    doAssertRaises(ValueError): discard parseFloatThousandSep("..")
    doAssertRaises(ValueError): discard parseFloatThousandSep("1,,000")
    doAssertRaises(ValueError): discard parseFloatThousandSep("1..000")
  block:
    doAssert parseFloatThousandSep(['0']) == 0.0
    doAssert parseFloatThousandSep(['-', '0']) == -0.0
    doAssert parseFloatThousandSep(['0', '.', '0']) == 0.0
    doAssert parseFloatThousandSep(['1', '.', '0']) == 1.0
    doAssert parseFloatThousandSep(['-', '0', '.', '0']) == -0.0
    doAssert parseFloatThousandSep(['-', '1', '.', '0']) == -1.0
    doAssert parseFloatThousandSep(['1', '.', '0', '0', '0']) == 1.0
    doAssert parseFloatThousandSep(['-', '1', '.', '0', '0', '0']) == -1.0
    doAssertRaises(ValueError): discard parseFloatThousandSep("1,0000.000")
    doAssertRaises(ValueError): discard parseFloatThousandSep(['-', '-'])
    doAssertRaises(ValueError): discard parseFloatThousandSep(['.', '.'])
    doAssertRaises(ValueError): discard parseFloatThousandSep(['1', ',', ',', '0', '0', '0'])
    doAssertRaises(ValueError): discard parseFloatThousandSep(['1', '.', '.', '0', '0', '0'])


main()
static: main()
