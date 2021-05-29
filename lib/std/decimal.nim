##[
  The `decimal` module supports the storage of numbers in decimal format.

  The primary benefit of this is it avoids conversion errors when converting to/from
  decimal (base 10) and binary (base 2). The is critical for applications where
  the numbers are start out as decimal, must be output as decimal, and even minor
  error are problematic. Financial and scientific lab programs, for example, often
  meet this requirement.

  As a secondary benefit, this library also honors the "significance" of a number
  and properly handles significance during mathematic operations.

  Examples
  ========
]##
runnableExamples:
  var a = newDecimal("1234.50")
  doAssert a.places == 2
  doAssert a.significantDigitCount == 6
  doAssert a.sci == "1.23450E+3"
##[
  .. code-block:: nim
    import decimal

  Parsing
  =======
  blah blah blah

]##

import std/strutils except strip
import std/[strformat, unicode]

#
# Type definitions
#

# public types
type
  Decimal* = object
    a: uint32
    b: uint32
    c: uint32
    d: uint32

# private types
type
  DecimalKind = enum
    # internal use: the state of the Decimal128 variable
    dkValued,
    dkInfinite,
    dkNaN
  SignificandArray = array[34, byte]
  TempSignificandArray = array[70, byte] # (34+1)*2
  Quotient = tuple[a: uint32, b: uint32, c: uint32, d: uint32]

#
# constants
#

# private constants
const
  significandSize: int = 34
  bias: int16 = 6176
  expLowerBound: int16 = 0 - bias
  tempSignificandSize: int = 70
  billion: uint32 = 1000 * 1000 * 1000 # a billion has 10 digits and fits into 32 bits
  tenThousand: uint16 = 10 * 1000      # 10 thousand has 5 digits and fits into 16 bits
  allZeroes: SignificandArray = [0.byte, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  transientOffset = tempSignificandSize - significandSize
  noValue: int16 = -32768


# masks (private)
const
  # all flags/exponents are in the first 32 bits ('a'), so they
  # are represented by the uint32
  # 
  # the exponent fits into 14 bits, but the mask determines the prefix, so you
  # really only have a range of 3 x 2^12 = 12288. So the bias of 6176 splits
  # that in half, thus fitting the official range of -6143 to +6144.
  signMask =                   0b1000_0000_0000_0000_0000_0000_0000_0000'u32
  #
  comboMask =                  0b0111_1111_1111_1111_1000_0000_0000_0000'u32
  #
  comboShortMask =             0b0110_0000_0000_0000_0000_0000_0000_0000'u32
  comboShortSignalsMedium =    0b0110_0000_0000_0000_0000_0000_0000_0000'u32
  comboShortExponentMask =     0b0111_1111_1111_1110_0000_0000_0000_0000'u32  # 14 bits
  comboShortExponentShiftR =   16 + 1
  #
  # medium is used when the leading bit in the significand happens to be 1
  comboMediumMask =            0b0111_1000_0000_0000_0000_0000_0000_0000'u32
  comboMediumSignalsLong =     0b0111_1000_0000_0000_0000_0000_0000_0000'u32
  comboMediumExponentMask =    0b0001_1111_1111_1111_1000_0000_0000_0000'u32
  comboMediumExponentShiftR =  15
  #
  comboLongMask =              0b0111_1100_0000_0000_0000_0000_0000_0000'u32
  comboLongInfinityFlag =      0b0111_1000_0000_0000_0000_0000_0000_0000'u32
  comboLongNanFlag =           0b0111_1100_0000_0000_0000_0000_0000_0000'u32
  comboLongSignalingNanFlag =  0b0000_0010_0000_0000_0000_0000_0000_0000'u32
  #
  # NOTE: the spec allows for sig combo bits and we are following BID variant.
  #
  # the largest significand is:
  #     9999999999999999999999999999999999 (decimal) or
  #    0001ed09_bead87c0_378d8e63_ffffffff (hex)
  # which fits neatly into 113 bits. So, the masks for the first 32 bits is:
  significandMaskUpper      =  0b0000_0000_0000_0001_1111_1111_1111_1111'u32
  significandMediumBit      =  0b0000_0000_0000_0001_0000_0000_0000_1111'u32
  #
  allOnes                   =  0b1111_1111_1111_1111_1111_1111_1111_1111'u32

when not defined(js):
  const
    upperOnes               =  0xFFFFFFFF00000000'u64
    lowerOnes               =  0x00000000FFFFFFFF'u64


# public constants
const
  nan* = Decimal(a: comboLongNanFlag, b:0, c:0, d:0)
  infinity* = Decimal(a: comboLongInfinityFlag, b: 0, c:0, d:0)
  negativeInfinity* = Decimal(a: (comboLongInfinityFlag or signMask), b: 0, c:0, d:0)

#
# private helpers
#

proc shiftDecimalsLeftWithZero(values: SignificandArray, shiftNeeded: int16): SignificandArray =
  for index in 0 ..< significandSize:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 0 ..< (significandSize - 1):
      result[index] = result[index + 1]
    result[33] = 0.byte


proc shiftDecimalsLeftTransientWithZero(values: TempSignificandArray, shiftNeeded: int16): TempSignificandArray =
  for index in 0 ..< tempSignificandSize:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 0 ..< (tempSignificandSize - 1):
      result[index] = result[index + 1]
    result[tempSignificandSize - 1] = 0.byte


proc shiftDecimalsRight(values: SignificandArray, shiftNeeded: int16): SignificandArray =
  for index in 0 ..< significandSize:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 1 ..< significandSize:
      let place = significandSize - index
      result[place] = result[place - 1]
    result[0] = 0.byte


proc shiftDecimalsRightTransient(values: TempSignificandArray, shiftNeeded: int16): TempSignificandArray =
  for index in 0 ..< tempSignificandSize:
    result[index] = values[index]
  for _ in 0 ..< shiftNeeded:
    for index in 1 ..< tempSignificandSize:
      let place = tempSignificandSize - index
      result[place] = result[place - 1]
    result[0] = 0.byte

proc digitCount(significand: SignificandArray): int =
  # get the number of digits, ignoring the leading zeroes;
  # special case: all zeroes results returns a result of zero
  result = 0
  var nonZeroFound = false
  for d in significand:
    if d != 0.byte:
      nonZeroFound = true
    if nonZeroFound:
      result += 1

proc digitCount(significand: TempSignificandArray): int =
  # get the number of digits, ignoring the leading zeroes;
  # special case: all zeroes results returns a result of zero
  result = 0
  var nonZeroFound = false
  for d in significand:
    if d != 0.byte:
      nonZeroFound = true
    if nonZeroFound:
      result += 1

proc toTempSignificandArray(original: SignificandArray): TempSignificandArray =
  for index in 0 ..< tempSignificandSize:
    let sIndex = index - transientOffset
    if sIndex >= 0:
      result[index] = original[sIndex]
    else:
      result[index] = 0.byte

when not defined(js):
  proc greaterOrEqualToOneBillion(val: Quotient): bool =
    # is the number in the four 32-bit uints greater than 1_000_000_000
    if val.a != 0'u32:
      result = true
    elif val.b != 0'u32:
      result = true
    elif ((val.c.uint64 shl 32) or val.d.uint64) >= billion.uint64:
      result = true
    else:
      result = false

  proc leftHalf(value: uint64): uint32 =
    # get the left (most significant) half of a 64-bit uint
    result = (value shr 32).uint32

  proc setLeftHalf(value: var uint64, newValue: uint64) =
    # when defined(js):
    #   value = (value and lowerOnes) shr 0
    #   let temp = (newValue and lowerOnes) shl 32  # shift new value to left
    #   value = (value or temp) shr 0               # OR into place
    # else:
    value = value and lowerOnes
    let temp = (newValue and lowerOnes) shl 32  # shift new value to left
    value = value or temp                       # OR into place

  proc rightHalf(value: uint64): uint32 =
    # get the right (least significant) half of a 64-bit uint
    result = ((value and lowerOnes) shr 0).uint32

  proc setRightHalf(value: var uint64, newValue: uint64) =
    value = (value and upperOnes) shr 0 # wipe out the right
    value = (value or (newValue and lowerOnes)) shr 0

proc divide(quotient: Quotient, divisor: uint32): (Quotient, uint32) =
  when defined(js):
    # TODO: write a version that only uses 32 bit uints
    # For JS, this is needed for bitops
    raise newException(Exception, "js support not written yet")
  else:
    var remainder = 0'u64
    var pending: tuple[left: uint64, right: uint64]
    pending.left = (quotient.a.uint64 shl 32) or quotient.b.uint64
    pending.right = (quotient.c.uint64 shl 32) or quotient.d.uint64

    remainder += pending.left.leftHalf()
    pending.left.setLeftHalf(remainder div divisor)
    remainder = remainder mod divisor

    remainder = remainder shl 32
    remainder += pending.left.rightHalf()
    pending.left.setRightHalf(remainder div divisor)
    remainder = remainder mod divisor

    remainder = remainder shl 32
    remainder += pending.right.leftHalf()
    pending.right.setLeftHalf(remainder div divisor)
    remainder = remainder mod divisor

    remainder = remainder shl 32
    remainder += pending.right.rightHalf()
    pending.right.setRightHalf(remainder div divisor)
    remainder = remainder mod divisor

    var resultQuotient: Quotient
    resultQuotient.a = pending.left.leftHalf()
    resultQuotient.b = pending.left.rightHalf()
    resultQuotient.c = pending.right.leftHalf()
    resultQuotient.d = pending.right.rightHalf()
    result = (resultQuotient, remainder.uint32)

proc shouldRoundUpWhenBankersRoundingToEven(values: TempSignificandArray, keyDigitIndex: int): bool =
  let keyDigit = values[keyDigitIndex]
  var lastDigit = 0.byte
  if keyDigitIndex > 0:
    lastDigit = values[keyDigitIndex - 1]
  #
  var AllZeroesFollowingKeyDigit: bool = true
  if keyDigitIndex < (tempSignificandSize - 1):
    for index in (keyDigitIndex + 1) ..< tempSignificandSize:
      if values[index] > 0.byte:
        AllZeroesFollowingKeyDigit = false
  #  
  if keyDigit < 5:         # ...123[4]12 becomes ...123
    result = false
  elif keyDigit > 5:       # ...123[6]12 becomes ...124
    result = true
  elif (keyDigit == 5) and (AllZeroesFollowingKeyDigit == false):  # ...123[5]12 becomes ...124
    result = true
  else:    # keydigit == 5 and all zeroes followed the 5
    # let evenFlag = ((values[keyDigitIndex - 1] mod 2.byte) == 0.byte)  # is the last digit (before the key digit) even?
    let evenFlag = ((lastDigit mod 2.byte) == 0.byte)  # is the last digit (before the key digit) even?    
    if evenFlag:
      result = false      # ...123[5]00 becomes ...124
    else:
      result = true       # ...122[5]00 becomes ...122


# TODO: add rounding test suite
proc bankersRoundingToEven(values: TempSignificandArray, reduction: int): (SignificandArray, int) =
  # Uses "bankers rounding" algorithm AKA "dutch rounding" and "round half to
  # even", a standard used in both finance and statistics to avoid bias.
  # 
  # https://en.wikipedia.org/wiki/Rounding#Round_half_to_even
  #
  # returns with the results fit into 34-digit array and actual reduction
  var sig: SignificandArray
  let origSignificance = digitCount(values)
  if origSignificance == 0:
    result = (allZeroes, 0)
  else:
    #
    # gather info needed for the rounding decision
    #
    var newSignificance = origSignificance - reduction
    var trimCount = reduction
    if newSignificance > significandSize:
      trimCount += (newSignificance - significandSize)
      newSignificance = origSignificance - trimCount
    if trimCount > 0:
      #
      # trimmed cut
      #
      let keyDigitIndex = tempSignificandSize - trimCount
      let roundUpFlag = shouldRoundUpWhenBankersRoundingToEven(values, keyDigitIndex)
      #
      # build trimmed significand (and detect problematic all-nines scenario)
      #
      var allNines = true
      for index in 0 ..< significandSize:
        sig[index] = values[index + transientOffset - trimCount]
        if sig[index] != 9.byte:
          allNines = false
      #
      # adjust if all-nines
      #
      if allNines:
        sig[0] = 0.byte
        trimCount += 1
      #
      # and do rounding
      #
      if roundUpFlag:
        var index = significandSize - 1 # start with last digit
        for counter in 0 ..< significandSize:
          sig[index] += 1.byte
          if sig[index] < 10:
            break  # done
          else:
            sig[index] = 0 # if it rounds up to "11", then set to zero and
            index -= 1        # increment the previous digit
    else:
      #
      # plain cut
      #
      for index in 0 ..< significandSize:
        sig[index] = values[index + transientOffset - trimCount]
    result = (sig, trimCount)
 
proc trimToSignificand(values: TempSignificandArray): (SignificandArray, int) =
  # Round from the temp array to a final array with rounding.
  #
  # A tuple is returned containing both the array and any exponential offset
  # needed.
  #
  # Uses "bankers rounding" algorithm AKA "dutch rounding" and "round half to
  # even", a standard used in both finance and statistics to avoid bias.
  # 
  # https://en.wikipedia.org/wiki/Rounding#Round_half_to_even
  result = bankersRoundingToEven(values, 0)

proc generateDigits(src: Decimal, upper: uint32): SignificandArray =
  # We are going to play a "trick" with the number "one billion" aka 1,000,000,000. That number has the following traits:
  #
  # * it fits into a 32-bit unsigned integer; we have a way of dividing a 113-bit (or 128-bit) number by a 32-bit number
  # * when a big number is divided by a billion:
  #      - the remainder is the "bottom nine" digits of that number (which also fits in 32-bit number)
  #      - the quotient is a number representing the top part of that number
  #
  # The maximum digits allowed by decimal is 34. We will keep dividing the number by a billion until we have a
  # quotient below one billion. Then, that quotient followed by the remainders represents the digits.
  #
  # here is an example showing the same idea but used with 100 (and two digits) to make it easier to visualize:
  #
  #   starting number: 90230427
  #
  #   90230427 / 100 = 902304 with remainder 27  # digits so far = "27"
  #   902304 / 100 = 9023 with remainder 4       # digits so far = "0427"
  #   9023 / 100 =  90 with remainder 23         # digits so far = "230427"
  #
  #   90 is less than 100, so the answer is "90" & "230427" which is "90230427"
  #
  when defined(js):
    # TODO: rewrite a version of that only uses 32bit numbers for bitops for javascript
    raise newException(Exception, "js support not written yet")
  else:
    var resultStr = ""
    var quotient: Quotient = (upper, src.b, src.c, src.d)
    if (quotient.a == 0) and (quotient.b == 0):
      # these are the easy cases:
      if quotient.c == 0:
        resultStr = $quotient.d
      else:
        resultStr = $(((quotient.c.uint64 shl 32) + quotient.d.uint64) shr 0)
    else:
      var remainder = 0'u32
      while quotient.greaterOrEqualToOneBillion:
        (quotient, remainder) = divide(quotient, billion)
        resultStr = fmt"{remainder:09}" & resultStr
      let quotientSmaller = quotient.d
      resultStr = fmt"{quotientSmaller:09}" & resultStr
    result = allZeroes
    var index = 33
    for ch in resultStr.reversed:
      result[index] = (ch.byte - '0'.byte)
      index -= 1
      if index < 0:
        break

proc determineKindExponentAndUpper(d: Decimal): (DecimalKind, int16, uint32) =
  var exponent = 0'i16
  var decType = dkValued
  var upper = 0'u32
  when defined(js):
    let combo = (d.a and comboMask) shr 0
    let comboShort = (combo and comboShortMask) shr 0
    if comboShort == comboShortSignalsMedium:
      let comboMedium = (combo and comboMediumMask) shr 0
      if comboMedium == comboMediumSignalsLong:
        #
        # interpret long combo
        #
        let comboLong = (combo and comboLongMask) shr 0
        if comboLong == comboLongInfinityFlag:
          decType = dkInfinite
        else:
          decType = dkNaN      
      else:
        #
        # interpret medium combo
        #
        exponent = (((comboMedium and comboMediumExponentMask) shr comboMediumExponentShiftR).int32 - bias).int16
        upper = (((d.a and significandMaskUpper) shr 0) or significandMediumBit) shr 0
    else:
      #
      # interpret short combo
      #
      exponent = (((combo and comboShortExponentMask) shr comboShortExponentShiftR).int32 - bias).int16
      upper = (d.a and significandMaskUpper) shr 0
  else:
    let combo = d.a and comboMask
    let comboShort = combo and comboShortMask
    if comboShort == comboShortSignalsMedium:
      let comboMedium = combo and comboMediumMask
      if comboMedium == comboMediumSignalsLong:
        #
        # interpret long combo
        #
        let comboLong = combo and comboLongMask
        if comboLong == comboLongInfinityFlag:
          decType = dkInfinite
        else:
          decType = dkNaN      
      else:
        #
        # interpret medium combo
        #
        exponent = (((comboMedium and comboMediumExponentMask) shr comboMediumExponentShiftR).int32 - bias).int16
        upper = (d.a and significandMaskUpper) or significandMediumBit
    else:
      #
      # interpret short combo
      #
      exponent = (((combo and comboShortExponentMask) shr comboShortExponentShiftR).int32 - bias).int16
      upper = d.a and significandMaskUpper
  result = (decType, exponent, upper)

when not defined(js):
  proc multU64(left, right: uint64): (uint64, uint64) =
    #
    # multiply two unsigned 64bit numbers into an unsigned 128bit result
    #
    let leftHigh = (left shr 32) and lowerOnes
    let leftLow = left and lowerOnes
    let rightHigh = (right shr 32) and lowerOnes
    let rightLow = right and lowerOnes

    var productHigh = leftHigh * rightHigh
    var productMidA = leftHigh * rightLow
    var productMidB = leftLow * rightHigh
    var productLow = leftLow * rightLow

    productHigh += productMidA shr 32
    productMidA = (productMidA and lowerOnes) + productMidB + (productLow shr 32)

    productHigh += productMidA shr 32
    productLow = (productMidA shl 32) + (productLow and lowerOnes)

    result = (productHigh, productLow)

proc createDecimal(negativeFlag: bool, significand: TempSignificandArray, startingExponent: int): Decimal =
  when defined(js):
    # TODO: write a version that only uses 32 bit uints
    # For JS, this is needed for bitops
    raise newException(Exception, "js support not written yet")
  else:
    const hundredQuadrillion: uint64 = 100_000_000_000_000_000'u64 # 1 followed by 17 zeroes
    var exponent = startingExponent

    var (digits, expAdjustment) = trimToSignificand(significand)
    exponent += expAdjustment
    #
    # calculate the binary value of the upper/left-hand 17 digits and the lower/right-hand 17 digits
    #
    var upperPart: uint64 = 0
    var lowerPart: uint64 = 0
    var power: uint64 = hundredQuadrillion
    for index in 0 ..< 17:
      power = power div 10
      if digits[index] != 0:  # to speed things up, we avoid multiplication by zero
        upperPart += digits[index].uint64 * power
      if digits[index + 17] != 0:
        lowerPart += (digits[index + 17].uint64 * power) shr 0
    if upperPart == 0.uint64:
      #
      # if the answer fits into the lower 17 digits, we are done already
      #
      result.a = 0'u32
      result.b = 0'u32
      result.c = (lowerPart shr 32).uint32      
      result.d = (lowerPart and allOnes).uint32
    else:
      #
      # move into 128 bits (which, at 34 decimals, will fit into 113 bits)
      #
      # four digit equivalent of algorithm using bytes and 100 as splitter:
      #    digits = [9, 4, 8, 7]
      #    (upperPart, lowerPart) = (94, 87)
      #    (upperBig, lowerBig) = 94 * 100 = 9400 = 0x03AE = (03, AE) = (3, 174)
      #    lowerFinal = (87 + 174) mod 256 = 5 # unsigned ints do modulo automatically
      #    upperFinal = upperBig
      #    if 5 < 174 or 5 < 87:
      #      upperFinal += 1  # aka "carry the one"
      let (upperBig, lowerBig) = multU64(upperPart, hundredQuadrillion)
      var lowerFinal = lowerPart + lowerBig

      var upperFinal = upperBig
      if (lowerFinal < lowerBig) or (lowerFinal < lowerPart):
        upperFinal += 1.uint64  # "carry the one" (in binary)

      result.a = (upperFinal shr 32).uint32
      result.b = (upperFinal and allOnes).uint32
      result.c = (lowerFinal shr 32).uint32
      result.d = (lowerFinal and allOnes).uint32
    #
    # set combo bits
    #
    if negativeFlag:
      result.a = result.a or signMask
    # unless invoking the medium/long combo (11), the exponent will overlay 00, 01, or 10 bits 1, 2
    # in other works, an in-range exponent will never have 11 in those two bits; which is why 11 is a flag
    let exponentMask = (exponent + bias.int).uint32 shl comboShortExponentShiftR
    result.a = result.a or exponentMask

proc parseFromString(str: string): (DecimalKind, bool, TempSignificandArray, int) =
  # used internally to parse a decimal string into a temporarary tuple value.
  type
    ParseState = enum
      psPre,            # we haven't found the number yet
      psLeadingZeroes,  # we are ignoring any leading zero(s)
      psLeadingMinus,   # we found a minus sign
      psIntCoeff,       # we are reading the the integer part of a decimal number (NN.nnn)
      psDecimalPoint,   # we found a single decimal point
      psFracCoeff,      # we are reading the decimals of a decimal number  (nn.NNN)
      psSignForExp,     # we are reading the +/- of an exponent
      psExp,            # we are reading the decimals of an exponent
      psDone            # ignore everything else
  const
    ignoredChars = ['_', ',']

  var significand: TempSignificandArray
  var negative: bool = false
  var exponent: int = 0

  let s = str.toLower().strip()
  if s.startsWith("nan"):
    result = (dkNaN, false, significand, exponent)
    return

  if s.startsWith("+inf"):
    result = (dkInfinite, false, significand, exponent)
    return
  if s.startsWith("inf"):
    result = (dkInfinite, false, significand, exponent)
    return
  if s.startsWith("-inf"):
    result = (dkInfinite, true, significand, exponent)
    return

  var state: ParseState = psPre
  var legit = false
  var digitList: seq[byte] = @[]
  var expDigitList = ""
  var expNegative = false

  for ch in s:
    #
    # detect change first
    #
    case state:
    of psPre:
      if ch == '-':
        state = psLeadingMinus
      elif ch == '0':
        state = psLeadingZeroes
      elif DIGITS.contains(ch):
        state = psIntCoeff
      elif ch == '.':  # yes, we are allowing numbers like ".123" even though that is bad form
        state = psDecimalPoint
    of psLeadingMinus:
      if ch == '0':
        state = psLeadingZeroes
      elif DIGITS.contains(ch):
        state = psIntCoeff
      elif ch == '.':  # yes, we are allowing numbers like "-.123" even though that is bad form
        state = psDecimalPoint
      else:
        state = psDone  # anything else is not legit
    of psLeadingZeroes:
      if ch == '0':
        discard
      elif DIGITS.contains(ch):
        state = psIntCoeff
      elif ch == '.':
        state = psDecimalPoint
      elif ch == 'e':
        state = psSignForExp
      else:
        state = psDone
    of psIntCoeff:
      if DIGITS.contains(ch):
        discard
      elif ignoredChars.contains(ch):
        discard
      elif ch == '.':
        state = psDecimalPoint
      elif ch == 'e':
        state = psSignForExp
      else:
        state = psDone
    of psDecimalPoint:
      if DIGITS.contains(ch):
        state = psFracCoeff
      else:
        state = psDone
    of psFracCoeff:
      if DIGITS.contains(ch):
        discard
      elif ignoredChars.contains(ch):
        discard
      elif ch == 'e':
        state = psSignForExp
      else:
        state = psDone
    of psSignForExp:
      if DIGITS.contains(ch):
        state = psExp
      elif (ch == '-') or (ch == '+'):
        discard
      else:
        state = psDone
    of psExp:
      if DIGITS.contains(ch):
        discard
      else:
        state = psDone
    of psDone:
      discard
    #
    # act on state
    #
    case state:
    of psPre:
      discard
    of psLeadingMinus:
      negative = true
    of psLeadingZeroes:
      legit = true
    of psIntCoeff:
      # given the state table, the 'find' function should never return -1
      if not ignoredChars.contains(ch):
        digitList.add(DIGITS.find(ch).byte)
        legit = true
    of psDecimalPoint:
      discard
    of psFracCoeff:
      # given the state table, the 'find' function should never return -1
      if not ignoredChars.contains(ch):
        digitList.add(DIGITS.find(ch).byte)
        exponent -= 1
        legit = true
    of psSignForExp:
      if ch == '-':
        expNegative = true
    of psExp:
      expDigitList &= ch
    of psDone:
      discard
  #
  # remove leading zeroes
  #
  var nonZeroFound = false
  var temp: seq[byte] = @[]
  for val in digitList:
    if val != 0.byte:
      nonZeroFound = true
    if nonZeroFound:
      temp.add val
  digitList = temp
  #
  # if too many digits, removing trailing digits.
  # Note: because this is on 70-digit Transient, simple "truncation" is good enough
  #
  if digitList.len > tempSignificandSize:
    let digitsToRemove = digitList.len - tempSignificandSize
    digitList = digitList[0 ..< tempSignificandSize]
    exponent += digitsToRemove
  #
  # move to result to final significand
  #
  let offset = tempSignificandSize - digitList.len
  for index, val in digitList:
    significand[index + offset] = val
  #
  # parse the exponent value
  #
  if expDigitList.len > 0:
    try:
      let exp = parseInt(expDigitList)
      if expNegative:
        exponent -= exp
      else:
        exponent += exp
      if exponent < expLowerBound:
        let shiftNeeded = (expLowerBound - exponent).int16
        significand = shiftDecimalsRightTransient(significand, shiftNeeded)
        exponent += shiftNeeded
    except:
      discard
  #
  result = (dkValued, negative, significand, exponent)

#
# attributes
#

proc negative*(number: Decimal): bool =
  when defined(js):
    if (number.a and signMask) shr 0 == signMask:
      result = true
    else:
      result = false
  else:
    if (number.a and signMask) == signMask:
      result = true
    else:
      result = false

proc significantDigitCount*(number: Decimal): int =
  ## Get the precise number of significant digits in the decimal number.
  ##
  ## If a real number, then it will be a number between 1 and 34. Even a value of "0" has
  ## one digit of Precision.
  ##
  ## A zero is returned if the number is not-a-number (NaN) or Infinity.
  let (decKind, exponent, upper) = determineKindExponentAndUpper(number)
  case decKind:
  of dkValued:
    let digits = generateDigits(number, upper)
    result = digitCount(digits)
    if result == 0:  # only a true zero value can generate this
      if exponent < 0:
        result = -exponent
      else:
        result = 1
  of dkInfinite:
    result = 0
  of dkNaN:
    result = 0

proc places*(number: Decimal): int =
  ## Get the precise number of known digits after/before the decimal point.
  ## Also referred to as "the number of decimal places"
  ##
  ## An integer has zero places.
  ##
  ## Some numbers can have negative places if the significance does not include
  ## lesser whole digits. For example, an estimate of 45 million is 45E+6
  ## (or 4.5E+7) and has -6 places.
  ##
  ## Think of missing digits as Nulls (?). So,
  ##
  ## 1123.30   (aka 1123.30???????...) has  2 places
  ## 1123.3    (aka 1123.3????????...) has  1 places
  ## 1123      (aka 1123.?????????...) has  0 places
  ## 1.1E+3    (aka 11??.?????????...) has -2 places
  ## 1E+3      (aka 1???.?????????...) has -3 places
  ##
  ## Zero can also be given decimal places.
  ##
  ## 0         (aka 0.??????????...) has 0 places
  ## 0.00000   (aka 0.00000?????...) has 5 places
  ##
  ## "0.00000" means the number is precisely zero to 5 decimals places.
  ##
  ## Infinite and NaN have no decimal places and will return a zero (0).
  let (decKind, exponent, upper) = determineKindExponentAndUpper(number)
  case decKind:
  of dkValued:
    result = -exponent
  of dkInfinite:
    result = 0
  of dkNaN:
    result = 0

proc `places=`*(number: var Decimal, newValue: int) {.inline.} =
  ## Change a Decimal to the supplied number decimal places.
  ##
  ## The scale must be a value from −6144 to +6143.
  ##
  ## A negative value means the significance is adjusted so that the
  ## value is only accurate to the number of digits *before* the decimal place.
  ##
  ## For example:
  ##     var x = newDecimal("123.4")
  ##     x.places = -1
  ##     assert $x == "12E1" # essentially, 120 rounded to the nearest ten.
  ##  
  ## When NaN or Infinity is passed, the decimal is unchanged.
  let (decKind, exponent, upper) = determineKindExponentAndUpper(number)
  case decKind:
  of dkValued:
    if newValue == noValue:
      return
    let currentPlaces = -exponent
    if currentPlaces != newValue:
      let digits = generateDigits(number, upper)
      var diff = (currentPlaces - newValue).int16
      if diff > 0: # take away precision
        let temp = digits.toTempSignificandArray()
        let (newDigits, roundingEffect) = bankersRoundingToEven(temp, diff)
        number = createDecimal(number.negative, newDigits.toTempSignificandArray, exponent + roundingEffect)
      else:
        let significance = digitCount(digits)
        let newSig = significance - diff
        if newSig > significandSize:
          raise newException(
            ValueError, 
            "Too many decimal places ($1 places for $2). A 128-bit decimal can only hold 34 digits ($3 rose to $4)."
              .format(newValue, $number, significance, newSig)
            )
        else:
          let newDigits = shiftDecimalsLeftWithZero(digits, -diff)
          number = createDecimal(number.negative, newDigits.toTempSignificandArray, exponent + diff)
  of dkInfinite:
    discard
  of dkNaN:
    discard


#
# ops
#

proc `~==`(left: Decimal, right: Decimal): bool =
  ## Determines whether two numbers match in the context of their
  ## least-common significance.
  ##
  ## For example:
  runnableExamples:
    assert (1.1'm  ~== 1.0'm ) == false
    assert (1.0'm  ~== 1.0'm ) == true
    assert (1.0'm  ~== 1.01'm) == true
    assert (1.01'm ~== 1.0'm ) == true
    assert (1.01'm ~== 1.00'm) == false
  ##
  ## Use this with care with currency or financial work:
  runnableExamples:
    assert (5'm    ~== 5.23'm) == true
    assert (5.00'm ~== 5.23'm) == false 
  #
  # let (leftKind, leftExponent, leftUpper) = determineKindExponentAndUpper(left)
  # let (rightKind, rightExponent, rightUpper) = determineKindExponentAndUpper(right)
  # case leftKind:
  # of dkValued:
  #   if rightKind != dkValues:
  #     result = false
  #     return
  #   if (leftExponent > rightExponent): # these values are -(places)
  #     let stripped = right.strip(-leftExponent)
  #     result = left == stripped
  #   else:
  #     let stripped = left.strip(-rightExponent)
  #     result = stripped == right
  # of dkInfinite:
  #   result = left == right
  # of dkNaN:
  #   result = left == right
  result = false # TODO

# proc '<'

# proc round  # bankers rounding

# proc roundUp

# proc strip

#
# assignment / input
#

proc newDecimal*(numberString: string, places: int = noValue): Decimal =
  var (decimalKind, negativeFlag, significand, exponent) = parseFromString(numberString)
  case decimalKind:
  of dkNaN:
    result = nan
  of dkInfinite:
    if negativeFlag:
      result = negativeInfinity
    else:
      result = infinity
  of dkValued:
    result = createDecimal(negativeFlag, significand, exponent)
    result.places = places

proc `'m`*(numberString: string, places: int = noValue): Decimal =
  newDecimal(numberString, places)

proc decodeHex*(hex: string): Decimal =
  if len(hex) != 32:
    raise newException(ValueError, "The Decimal data type takes 32 hex characters. This string has $1.".format(hex.len))
  var part = hex[0 .. 7]
  result.a = fromHex[uint32](part)
  part = hex[8 .. 15]
  result.b = fromHex[uint32](part)
  part = hex[16 .. 23]
  result.c = fromHex[uint32](part)
  part = hex[24 .. 31]
  result.d = fromHex[uint32](part)

#
# output
#

proc simpleDigitStr(dList: SignificandArray): string =
  var firstDigitSeen = false
  for digit in dList:
    if digit != 0.byte:
      firstDigitSeen = true
    if firstDigitSeen:
      result &= $(digit.int)
  if not firstDigitSeen:
    result = "0"

proc generateNumberString(number: Decimal, exponent: int16, upper: uint32): string =
  # from the lower three uint32 in decimal and the masked upper uint32 (upper),
  # derive a sequence of decimal bytes.
  if number.negative:
    result = "-"
  else:
    result = ""

  let digits = generateDigits(number, upper)
  let justDigits = simpleDigitStr(digits)

  let scientificExponent = justDigits.len - 1 + exponent
  if (scientificExponent < -6) or (exponent > 0):
    # express with scientific notation
    for index, ch in justDigits:
      if index == 1:
        result &= "."
      result &= ch
    result &= "E"
    if scientificExponent >= 0:
      result &= "+"
    result &= $scientificExponent
  elif exponent == 0:
    # if zero decimal places, then it is a simple integer
    result &= justDigits
  else:
    let significance = -exponent
    let leadingZeroes = significance - justDigits.len
    if leadingZeroes >= 0:
      result &= "0."
      result &= "0".repeat(leadingZeroes)
      result &= justDigits
    else:
      let depth = -leadingZeroes
      for index, ch in justDigits:
        if index == depth:
          result &= "."
        result &= ch

proc sci*(number: Decimal): string =
  ## Express the Decimal value in Scientific Notation
  let (decKind, exponent, upper) = determineKindExponentAndUpper(number)
  case deckind:
  of dkValued:
    let digits = generateDigits(number, upper)
    let justDigits = simpleDigitStr(digits)
    let scientificExponent = justDigits.len - 1 + exponent
    for index, ch in justDigits:
      if index == 1:
        result &= "."
      result &= ch
    result &= "E"
    if scientificExponent >= 0:
      result &= "+"
    result &= $scientificExponent
  of dkInfinite:
    if number.negative:
      result = "-Infinity"
    else:
      result = "Infinity"
  of dkNaN:
    result = "NaN"

proc `$`*(number: Decimal): string =
  ## Express the Decimal value as a canonical string
  var (decKind, exponent, upper) = determineKindExponentAndUpper(number)
  case deckind:
  of dkValued:
    result &= generateNumberString(number, exponent, upper)
  of dkInfinite:
    if number.negative:
      result = "-Infinity"
    else:
      result = "Infinity"
  of dkNaN:
    result = "NaN"

proc internalRepr*(number: Decimal): string =
  "Decimal($1 $2 $3 $4)".format(number.a, number.b, number.c, number.d)

proc toHex*(number: Decimal): string =
  number.a.toHex & number.b.toHex & number.c.toHex & number.d.toHex
