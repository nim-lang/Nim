const
  trailingZeros100: array[100, int8] = [2'i8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0,
    0, 0, 0, 0, 0, 0]

  digits100: array[200, char] = ['0', '0', '0', '1', '0', '2', '0', '3', '0', '4', '0', '5',
    '0', '6', '0', '7', '0', '8', '0', '9', '1', '0', '1', '1', '1', '2', '1', '3', '1', '4',
    '1', '5', '1', '6', '1', '7', '1', '8', '1', '9', '2', '0', '2', '1', '2', '2', '2', '3',
    '2', '4', '2', '5', '2', '6', '2', '7', '2', '8', '2', '9', '3', '0', '3', '1', '3', '2',
    '3', '3', '3', '4', '3', '5', '3', '6', '3', '7', '3', '8', '3', '9', '4', '0', '4', '1',
    '4', '2', '4', '3', '4', '4', '4', '5', '4', '6', '4', '7', '4', '8', '4', '9', '5', '0',
    '5', '1', '5', '2', '5', '3', '5', '4', '5', '5', '5', '6', '5', '7', '5', '8', '5', '9',
    '6', '0', '6', '1', '6', '2', '6', '3', '6', '4', '6', '5', '6', '6', '6', '7', '6', '8',
    '6', '9', '7', '0', '7', '1', '7', '2', '7', '3', '7', '4', '7', '5', '7', '6', '7', '7',
    '7', '8', '7', '9', '8', '0', '8', '1', '8', '2', '8', '3', '8', '4', '8', '5', '8', '6',
    '8', '7', '8', '8', '8', '9', '9', '0', '9', '1', '9', '2', '9', '3', '9', '4', '9', '5',
    '9', '6', '9', '7', '9', '8', '9', '9']

# Inspired by https://engineering.fb.com/2013/03/15/developer-tools/three-optimization-tips-for-c
# Generates:
# .. code-block:: nim
#   var res = ""
#   for i in 0 .. 99:
#     if i < 10:
#       res.add "0" & $i
#     else:
#       res.add $i
#   doAssert res == digits100

proc utoa2Digits*(buf: var openArray[char]; pos: int; digits: uint32) {.inline.} =
  assert(digits <= 99)
  buf[pos] = digits100[2 * digits]
  buf[pos+1] = digits100[2 * digits + 1]
  #copyMem(buf, unsafeAddr(digits100[2 * digits]), 2 * sizeof((char)))

proc trailingZeros2Digits*(digits: uint32): int32 {.inline.} =
  assert(digits <= 99)
  return trailingZeros100[digits]

proc firstPow10(n: int): uint64 {.compileTime.} =
  case n
  of 1: 1'u64
  of 2: 10'u64
  of 3: 100'u64
  of 4: 1000'u64
  of 5: 10000'u64
  of 6: 100000'u64
  of 7: 1000000'u64
  of 8: 10000000'u64
  of 9: 100000000'u64
  of 10: 1000000000'u64
  of 11: 10000000000'u64
  of 12: 100000000000'u64
  of 13: 1000000000000'u64
  of 14: 10000000000000'u64
  of 15: 100000000000000'u64
  of 16: 1000000000000000'u64
  of 17: 10000000000000000'u64
  of 18: 100000000000000000'u64
  of 19: 1000000000000000000'u64
  of 20: 10000000000000000000'u64
  else:
    doAssert false
    0'u64

func digits10*(x: uint64): int {.inline.} =
  if x >= firstPow10(11): # 1..10, 11..20
    if x >= firstPow10(16): # 11..15, 16..20
      if x >= firstPow10(18): # 16..17, 18..20
        if x >= firstPow10(19): # 18, 19..20
          if x >= firstPow10(20): 20 # 19, 20
          else: 19
        else: 18
      elif x >= firstPow10(17): 17 # 16, 17
      else: 16
    elif x >= firstPow10(13): # 11..12, 13..15
      if x >= firstPow10(14): # 13, 14..15
        if x >= firstPow10(15): 15 # 14, 15
        else: 14
      else: 13
    elif x >= firstPow10(12): 12 # 11, 12
    else: 11
  elif x >= firstPow10(6): # 1..5, 6..10
    if x >= firstPow10(8): # 6..7, 8..10
      if x >= firstPow10(9): # 8, 9..10
        if x >= firstPow10(10): 10 # 9, 10
        else: 9
      else: 8
    elif x >= firstPow10(7): 7 # 6, 7
    else: 6
  elif x >= firstPow10(3): # 1..2, 3..5
    if x >= firstPow10(4): # 3, 4..5
      if x >= firstPow10(5): 5 # 4, 5
      else: 4
    else: 3
  elif x >= firstPow10(2): 2 # 1, 2
  else: 1

proc numToString*(result: var string, origin: uint64, length: int) {.inline.} =
  var x = origin
  var i = result.len - 2
  while i >= 0:
    let xi = (x mod 100) shl 1
    x = x div 100
    # copies 2 chars at a time
    cast[ptr uint16](result[i].unsafeAddr)[] = cast[ptr uint16](digits100[xi].unsafeAddr)[]
    i = i - 2
  if i == -1: # copy last digit if odd number
    result[0] = chr(ord('0') + x)
