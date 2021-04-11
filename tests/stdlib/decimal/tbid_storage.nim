discard """
  targets: "c cpp"
"""

import helpers

# Internally, decimal is stored per the IEEE spec with the Binary Integer 
# Decimal variant; https://en.wikipedia.org/wiki/Binary_integer_decimal
#
# these test ensure that the internal storage is being correctly built
# and interpreted.

# Many original test cases adapted from:
#    * https://github.com/mongodb/mongo-java-driver/blob/master/bson/src/test/unit/org/bson/types/Decimal128Test.java
#    * ...

var canonicalHexBin = ""
var canonicalStr = ""
var nonCanonicalStrs: seq[string] = @[]
var resultLossy = false

canonicalHexBin = "7c000000000000000000000000000000"
canonicalStr = "NaN"
nonCanonicalStrs = @[
  "nan",
  "nAn"
]
resultLossy = false
conversionTest(1, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

canonicalHexBin = "78000000000000000000000000000000"
canonicalStr = "Infinity"
nonCanonicalStrs = @[
  "infinity",
  "+infinity",
  "inf",
  "+inf",
  "infiniTY",
  "inF"
]
resultLossy = false
conversionTest(2, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

canonicalHexBin = "f8000000000000000000000000000000"
canonicalStr = "-Infinity"
nonCanonicalStrs = @[
  "-infinity",
  "-inf"
]
resultLossy = false
conversionTest(3, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

canonicalHexBin = "30400000000000000000000000000000"
canonicalStr = "0"
resultLossy = false
conversionTest(4, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "b0400000000000000000000000000000"
canonicalStr = "-0"
resultLossy = false
conversionTest(5, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "30400000000000000000000000000001"
canonicalStr = "1"
resultLossy = false
conversionTest(6, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "b0400000000000000000000000000001"
canonicalStr = "-1"
resultLossy = false
conversionTest(7, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "3040000000000000000000000000007B"
canonicalStr = "123"
resultLossy = false
conversionTest(8, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "304000000000000000000000000001C8"
canonicalStr = "456"
resultLossy = false
conversionTest(9, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "30400000000000000000000000000315"
canonicalStr = "789"
resultLossy = false
conversionTest(10, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "304000000000000000000000000003E7"
canonicalStr = "999"
resultLossy = false
conversionTest(11, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "304000000000000000000000000003E8"
canonicalStr = "1000"
resultLossy = false
conversionTest(12, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "304000000000000000000000000003FF"
canonicalStr = "1023"
resultLossy = false
conversionTest(13, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "30400000000000000000000000000400"
canonicalStr = "1024"
resultLossy = false
conversionTest(14, canonicalHexBin, canonicalStr, resultLossy, @[])

canonicalHexBin = "3040000000000000000000000098967F"
canonicalStr = "9999999"
resultLossy = false
conversionTest(15, canonicalHexBin, canonicalStr, resultLossy, @[])

# nine nines (one less than 1 billion)
canonicalHexBin = "3040000000000000000000003B9AC9FF"
canonicalStr = "999999999"
resultLossy = false
conversionTest(16, canonicalHexBin, canonicalStr, resultLossy, @[])

# one billion exactly
canonicalHexBin = "3040000000000000000000003B9ACA00"
canonicalStr = "1000000000"
resultLossy = false
conversionTest(17, canonicalHexBin, canonicalStr, resultLossy, @[])

# one billion plus 1
canonicalHexBin = "3040000000000000000000003B9ACA01"
canonicalStr = "1000000001"
resultLossy = false
conversionTest(18, canonicalHexBin, canonicalStr, resultLossy, @[])

# 10 ^ 25 (more than 64 bits and lots of zeroes)
canonicalHexBin = "3040000000084595161401484A000000"
canonicalStr = "10000000000000000000000000"
resultLossy = false
conversionTest(19, canonicalHexBin, canonicalStr, resultLossy, @[])

# all 34 digits filled
canonicalHexBin = "30403CDE6FFF9732DE825CD07E96AFF2"
canonicalStr = "1234567890123456789012345678901234"
nonCanonicalStrs = @[
  "+1234567890123456789012345678901234"
]
resultLossy = false
conversionTest(20, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# 34 nines
canonicalHexBin = "3041ED09BEAD87C0378D8E63FFFFFFFF"
canonicalStr = "9999999999999999999999999999999999"
resultLossy = false
conversionTest(21, canonicalHexBin, canonicalStr, resultLossy, @[])

# 34 nines and a zero
canonicalHexBin = "3044314DC6448D9338C15B09FFFFFFFF"
canonicalStr = "9.99999999999999999999999999999999E+34"
nonCanonicalStrs = @[
  "99999999999999999999999999999999990",
  "9999999999999999999999999999999999E1"
]
resultLossy = false
conversionTest(22, canonicalHexBin, canonicalStr, resultLossy, @[])

# 34 nines and a six
canonicalHexBin = "3044314DC6448D9338C15B0A00000000"
canonicalStr = "1.000000000000000000000000000000000E+35"
nonCanonicalStrs = @[
  "99999999999999999999999999999999996"
]
resultLossy = false
conversionTest(23, canonicalHexBin, canonicalStr, resultLossy, @[])

# Regular - 0.1
canonicalHexBin = "303E0000000000000000000000000001"
canonicalStr = "0.1"
resultLossy = false
conversionTest(24, canonicalHexBin, canonicalStr, resultLossy, @[])

# Regular - 0.1234567890123456789012345678901234
canonicalHexBin = "2FFC3CDE6FFF9732DE825CD07E96AFF2"
canonicalStr = "0.1234567890123456789012345678901234"
resultLossy = false
conversionTest(25, canonicalHexBin, canonicalStr, resultLossy, @[])

# Regular - Small
canonicalHexBin = "303400000000000000000000000004D2"
canonicalStr = "0.001234"
resultLossy = false
conversionTest(26, canonicalHexBin, canonicalStr, resultLossy, @[])

# Regular - Small with Trailing Zeros
canonicalHexBin = "302C0000000000000000000000BC4B20"
canonicalStr = "0.0012340000"
resultLossy = false
conversionTest(27, canonicalHexBin, canonicalStr, resultLossy, @[])

# Small with Max Significance (34 digits)
canonicalHexBin = "2FF83CD7450BE3F39FA2D32880000000"
canonicalStr = "0.001234000000000000000000000000000000"
nonCanonicalStrs = @[
  "0.001234000000000000000000000000000000E0",
  "0.1234000000000000000000000000000000E-2",
  "1.234000000000000000000000000000000E-3",
  "0.0012340000000000000000000000000000000", # should "trim" back to 34
  "0.00123400000000000000000000000000000000000" # should "trim" back to 34
]
resultLossy = false
conversionTest(28, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Regular - -0.0",
canonicalHexBin = "B03E0000000000000000000000000000"
canonicalStr = "-0.0"
resultLossy = false
conversionTest(29, canonicalHexBin, canonicalStr, resultLossy, @[])

# Regular - 2.000
canonicalHexBin = "303A00000000000000000000000007D0"
canonicalStr = "2.000"
resultLossy = false
conversionTest(30, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - Tiniest
canonicalHexBin = "0001ED09BEAD87C0378D8E63FFFFFFFF"
canonicalStr = "9.999999999999999999999999999999999E-6143"
nonCanonicalStrs = @[
  "9.9999999999999999999999999999999999999999E-6143" # should "clamp" back to 34 nines
]
resultLossy = false
conversionTest(31, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Scientific - Tiny
canonicalHexBin = "00000000000000000000000000000001"
canonicalStr = "1E-6176"
resultLossy = false
conversionTest(32, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - Negative Tiny
canonicalHexBin = "80000000000000000000000000000001"
canonicalStr =  "-1E-6176"
nonCanonicalStrs = @[
  "-10E-6177"  
]
resultLossy = false
conversionTest(33, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Scientific - Adjusted Exponent Limit
canonicalHexBin = "2FF03CDE6FFF9732DE825CD07E96AFF2"
canonicalStr = "1.234567890123456789012345678901234E-7"
resultLossy = false
conversionTest(34, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - Fractional
canonicalHexBin = "B02C0000000000000000000000000064"
canonicalStr = "-1.00E-8"
nonCanonicalStrs = @[
  "-100E-10"
]
resultLossy = false
conversionTest(35, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Scientific - 0 with Exponent
canonicalHexBin = "5F200000000000000000000000000000"
canonicalStr = "0E+6000"
resultLossy = false
conversionTest(36, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - 0 with Negative Exponent
canonicalHexBin = "2B7A0000000000000000000000000000"
canonicalStr = "0E-611"
resultLossy = false
conversionTest(37, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - No Decimal with Signed Exponent
canonicalHexBin = "30460000000000000000000000000001"
canonicalStr = "1E+3"
nonCanonicalStrs = @[
  "1E3",
  "1e3"
]
resultLossy = false
conversionTest(38, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Scientific - Trailing Zero
canonicalHexBin = "3042000000000000000000000000041A"
canonicalStr = "1.050E+4"
resultLossy = false
conversionTest(39, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - With Decimal
canonicalHexBin = "30420000000000000000000000000069"
canonicalStr = "1.05E+3"
resultLossy = false
conversionTest(40, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - Full
canonicalHexBin = "3040FFFFFFFFFFFFFFFFFFFFFFFFFFFF"
canonicalStr = "5192296858534827628530496329220095"
resultLossy = false
conversionTest(41, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - Large
canonicalHexBin = "5FFE314DC6448D9338C15B0A00000000"
canonicalStr = "1.000000000000000000000000000000000E+6144"
resultLossy = false
conversionTest(42, canonicalHexBin, canonicalStr, resultLossy, @[])

# Scientific - Largest
canonicalHexBin = "5FFFED09BEAD87C0378D8E63FFFFFFFF"
canonicalStr = "9.999999999999999999999999999999999E+6144"
resultLossy = false
conversionTest(43, canonicalHexBin, canonicalStr, resultLossy, @[])

# Non-Canonical Parsing - Long Decimal String
canonicalStr = "1E-999"
canonicalHexBin = "28720000000000000000000000000001"
nonCanonicalStrs = @[
  ".000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001"
]
resultLossy = false
conversionTest(44, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Non-Canonical Parsing - Long Significand with Exponent
canonicalHexBin = "305800000000029D42DA3A76F9E0D979"
canonicalStr = "1.2345689012345789012345E+34"
nonCanonicalStrs = @[
  "12345689012345789012345E+12"
]
resultLossy = false
conversionTest(45, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# Exact rounding
canonicalHexBin = "37CC314DC6448D9338C15B0A00000000"
canonicalStr = "1.000000000000000000000000000000000E+999"
nonCanonicalStrs = @[
  "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
]
resultLossy = false
conversionTest(46, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)

# from "Clamped" check in other test suite, but ... corrected?
canonicalHexBin = "5FFE000000000000000000000000000A"
canonicalStr = "1.0E+6112"
nonCanonicalStrs = @[
  "10E6111"
]
resultLossy = false
conversionTest(47, canonicalHexBin, canonicalStr, resultLossy, nonCanonicalStrs)
