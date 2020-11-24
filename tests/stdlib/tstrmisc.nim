import strmisc


func main() =
  doAssert parseFloatThousandSep("0.0") == 0.0
  doAssert parseFloatThousandSep("1.0") == 1.0
  doAssert parseFloatThousandSep("-0.0") == -0.0
  doAssert parseFloatThousandSep("-1.0") == -1.0
  doAssert parseFloatThousandSep("1.000") == 1.0
  doAssert parseFloatThousandSep("1.000") == 1.0
  doAssert parseFloatThousandSep("-1.000") == -1.0
  doAssert parseFloatThousandSep("-1,222.0001") == -1222.0001
  doAssert parseFloatThousandSep("3.141592653589793") == 3.141592653589793
  doAssert parseFloatThousandSep("6.283185307179586") == 6.283185307179586
  doAssert parseFloatThousandSep("2.718281828459045") == 2.718281828459045

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
  doAssertRaises(ValueError): discard parseFloatThousandSep(" ", {pfDotOptional})
  doAssertRaises(ValueError): discard parseFloatThousandSep(".1.", {pfLeadingDot,pfTrailingDot})
  doAssertRaises(ValueError): discard parseFloatThousandSep("10,00.0")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1.0e9")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1.0e-9")
  doAssertRaises(ValueError): discard parseFloatThousandSep("1,000.000ee9", {pfScientific})
  doAssertRaises(ValueError): discard parseFloatThousandSep("1ee9", {pfScientific, pfDotOptional})
  doAssertRaises(ValueError): discard parseFloatThousandSep("1e02.2", {pfScientific})
  doAssertRaises(ValueError): discard parseFloatThousandSep("1.0e--9", {pfScientific})

  doAssert parseFloatThousandSep("10,00.0", {pfSepAnywhere}) == 1000.0
  doAssert parseFloatThousandSep("0", {pfDotOptional}) == 0.0
  doAssert parseFloatThousandSep("-0", {pfDotOptional}) == -0.0
  doAssert parseFloatThousandSep("1,111", {pfDotOptional}) == 1111.0
  doAssert parseFloatThousandSep(".1", {pfLeadingDot}) == 0.1
  doAssert parseFloatThousandSep("1.", {pfTrailingDot}) == 1.0
  doAssert parseFloatThousandSep(".1", {pfLeadingDot,pfTrailingDot}) == 0.1
  doAssert parseFloatThousandSep("1.", {pfLeadingDot,pfTrailingDot}) == 1.0
  doAssert parseFloatThousandSep("1", {pfDotOptional}) == 1.0
  doAssert parseFloatThousandSep("1.0,0,0", {pfSepAnywhere}) == 1.0
  doAssert parseFloatThousandSep(".10", {pfLeadingDot}) == 0.1
  doAssert parseFloatThousandSep("10.", {pfTrailingDot}) == 10.0
  doAssert parseFloatThousandSep("10", {pfDotOptional, pfSepAnywhere}) == 10.0
  doAssert parseFloatThousandSep("1.0,0,0,0,0,0,0,0", {pfSepAnywhere}) == 1.0
  doAssert parseFloatThousandSep("0,0,0,0,0,0,0,0.1", {pfSepAnywhere}) == 0.1
  doAssert parseFloatThousandSep("1.0e9", {pfScientific}) == 1000000000.0
  doAssert parseFloatThousandSep("1.0e-9", {pfScientific}) == 1e-09
  doAssert parseFloatThousandSep("1,000.000e9", {pfScientific}) == 1000000000000.0
  doAssert parseFloatThousandSep("1e9", {pfScientific, pfDotOptional}) == 1000000000.0
  doAssert parseFloatThousandSep("1.0E9", {pfScientific}) == 1000000000.0
  doAssert parseFloatThousandSep("1.0E-9", {pfScientific}) == 1e-09


main()
static: main()
