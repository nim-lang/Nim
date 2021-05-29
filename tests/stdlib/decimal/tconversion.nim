discard """
  targets: "c cpp"
"""

import std/decimal

import helpers

let refAThree = newDecimal("199")       # 3 sig digits
let refANine = newDecimal("199.000000") # 9 sig digits

let refBThree = newDecimal("0.123")
let refBNine = newDecimal("0.123000000")

let refCThree = newDecimal("567E+6")
let refCNine = newDecimal("567_000_000")

block: # string tests
    let testAThree = newDecimal("199.")

    assertEquals(testAThree, refAThree)
    assertEquals($testAThree, "199")
    assertEquals(testAThree.sci, "1.99E+2")
    assertEquals(testAThree.significantDigitCount, 3)
    assertEquals(testAThree.places, 0)
    assertEquals(testAThree, 199'm)  # this is actually a string test
    assertEquals(testAThree, newDecimal("199.00", places=0))
    assertEquals(testAThree, 199.00'm(0))

    let testANine = newDecimal("000199.000000")

    assertEquals(testANine, refANine)
    assertEquals($testANine, "199.000000")
    assertEquals(testANine.sci, "1.99000000E+2")
    assertEquals(testANine.significantDigitCount, 9)
    assertEquals(testANine.places, 6)
    assertEquals(testANine, newDecimal("199.00", places=6))
    assertEquals(testANine, 199.0'm(places=6))

    let testBThree = newDecimal(".123")

    assertEquals(testBThree, refBThree)
    assertEquals($testBThree, "0.123")
    assertEquals(testBThree.sci, "1.23E-1")
    assertEquals(testBThree.significantDigitCount, 3)
    assertEquals(testBThree.places, 3)
    assertEquals(testBThree, newDecimal("0.12340", places=3))
    assertEquals(testBThree, 0.123444'm(places = 3))

    let testBNine = newDecimal("0000.123000000")

    assertEquals(testBNine, refBNine)
    assertEquals($testBNine, "0.123000000")
    assertEquals(testBNine.sci, "1.23000000E-1")
    assertEquals(testBNine.significantDigitCount, 9)
    assertEquals(testBNine.places, 9)
    assertEquals(testBNine, newDecimal("0.123", places=9))
    assertEquals(testBNine, 0.12300'm(places=9))

    let testCThree = newDecimal("0.567E9")

    assertEquals(testCThree, refCThree)
    assertEquals($testCThree, "5.67E+8")
    assertEquals(testCThree.sci, "5.67E+8")
    assertEquals(testCThree.significantDigitCount, 3)
    assertEquals(testCThree.places, -6)
    assertEquals(testCThree, newDecimal("5.670000E+8", places= -6))
    assertEquals(testCThree, 567000000'm(places= -6))

    let testCNine = newDecimal("000000000567000000")

    assertEquals(testCNine, refCNine)
    assertEquals($testCNine, "567000000")
    assertEquals(testCNine, 567000000'm)
    assertEquals(testCNine.sci, "5.67000000E+8")
    assertEquals(testCNine.significantDigitCount, 9)
    assertEquals(testCNine.places, 0)
    assertEquals(testCNine, newDecimal("5.67E8", places=0))

    # TODO: add octal, binary, hex string conversions (sans 'E' exponent support)

# block: # integer tests
#     let testAThree = newDecimal(199)

#     assertEquals(testAThree, refAThree)
#     assertEquals($testAThree, "199")
#     assertEquals(testAThree.significantDigitCount, 3)
#     # assertEquals(testAThree.places, 0)
#     # assertEquals(testAThree.getExponent, 0)
#     # assertEquals(testAThree.toInt, 199)
#     # assertEquals(testAThree, newDecimal(199,) places=0)

#     let testANine = newDecimal(199, significantDigitCount=9)

#     assertEquals(testANine, refANine)
#     assertEquals($testANine, "199.000000")
#     assertEquals(testANine.significantDigitCount, 9)
#     # assertEquals(testANine.getExponent, 0)
#     # assertEquals(testANine.places, 6)
#     # assertEquals(testANine.toInt, 199)
#     # assertEquals(testANine, newDecimal(199,) places=6)

#     let testCThree = newDecimal(567000000, significantDigitCount=3)

#     assertEquals(testCThree, refCThree)
#     assertEquals($testCThree, "5.67E+8")
#     assertEquals(testCThree.significantDigitCount, 3)
#     # assertEquals(testCThree.places, 0)
#     # assertEquals(testCThree.getExponent, 6)
#     # assertEquals(testCThree.toInt, 567000000)
#     assertEquals(testCThree, newDecimal(567000000,) places= -6)

#     let testCNine = newDecimal(567000000, scale=9)

#     assertEquals(testCNine, refCNine)
#     assertEquals($testCNine, "567000000")
#     assertEquals(testCNine.significantDigitCount, 9)
#     # assertEquals(testCNine.places, 0)
#     # assertEquals(testCNine.getExponent, 0)
#     # assertEquals(testCNine.toInt, 567000000)
#     assertEquals(testCNine, newDecimal(567000000,) scale=0)

# block: # test float conversion
#     let testA = newDecimal(199.0) # floats don't store "zeroes after decimal point"

#     assertEquals(testA, refAThree)
#     assertEquals($testA, "199")
#     assertEquals(testA.significantDigitCount, 3)
#     # assertEquals(testA.places, 0)
#     # assertEquals(testA.getExponent, 0)
#     # assertEquals(testA.toFloat, 199.0)
#     # assertEquals(testA.toFloat, 199'f)
#     # assertEquals(testA.toFloat, 199.0000000)

#     let testB = newDecimal(0.123)
    
#     assertEquals($testB, "0.123")
#     assertEquals(testB.significantDigitCount, 3)
#     # assertEquals(testB.places, 3)
#     # assertEquals(testB.getExponent, 0)
#     # assertEquals(testB.toFloat, 0.123)

#     let testC = newDecimal(567000000.0)
    
#     assertEquals($testC, "567000000")
#     assertEquals(testC.significantDigitCount, 9)
#     assertEquals(testC.places, 0)
#     # assertEquals(testC.getExponent, 0)
#     # assertEquals(testC.toFloat, 567000000.0)

#     let testD = newDecimal(1.0 / 7.0) # this is a repeating number in binary float
    
#     assertEquals($testD, "0.1428571428571428")
#     assertEquals(testD.significantDigitCount, 16)
#     assertEquals(testD.places, 16)
#     # assertEquals(testD.getExponent, -16)
#     # assertEquals(testD.toFloat, 0.1428571428571428)
#     # doAssert testD.toFloat != (1.0 / 7.0)  # due to base10/base2 conversions

#     let testE = newDecimal( -5000.0 * (1.0 / 5.0) )
    
#     assertEquals($testE, "-1000")
#     assertEquals(testE.significantDigitCount, 4)
#     # assertEquals(testE.places, 0)
#     # assertEquals(testE.getExponent, 0)
#     # assertEquals(testE.toFloat, -1000.0)
#     # assertEquals(testE.toFloat, () -5000.0 * (1.0 / 5.0) )

#     let testF = newDecimal(1.123)
    
#     assertEquals($testF, "1.123")
#     assertEquals(testF.significantDigitCount, 4)
#     # assertEquals(testF.places, 3)
#     # assertEquals(testF.getExponent, 0)
#     # assertEquals(testF.toFloat, 1.123)
