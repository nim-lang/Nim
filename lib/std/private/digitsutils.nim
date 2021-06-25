proc c_memcpy(a, b: pointer, size: csize_t): pointer {.importc: "memcpy", header: "<string.h>", discardable.}

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
  # xxx use `c_memcpy`; likewise in dragonbox, after measuring performance.
  #copyMem(buf, unsafeAddr(digits100[2 * digits]), 2 * sizeof((char)))

proc trailingZeros2Digits*(digits: uint32): int32 {.inline.} =
  assert(digits <= 99)
  return trailingZeros100[digits]

proc firstPow10(n: int): uint64 {.compileTime.} =
  result = 1
  for i in 1..<n: result *= 10

func digits10*(x: uint64): int {.inline.} =
  ## Returns number of digits of `$x`
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

func digits10*(x: uint32): int {.inline.} =
  ## Returns number of digits of `$x`
  if x >= firstPow10(6): # 1..5, 6..10
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

template addIntImpl2[T](ret: T, num: uint64, length: int, start: int) =
  var i = length - 2
  var x = num
  while i >= 0:
    let xi = (x mod 100) shl 1
    x = x div 100
    template fallback =
      ret[i + start] = digits100[xi]
      ret[i+1 + start] = digits100[xi+1]
    when nimvm: fallback()
    else:
      when defined(nimHasDragonBox): # pending bootstrap >= 1.4.0
        c_memcpy ret[i + start].addr, digits100[xi].unsafeAddr, 2
      else:
        fallback()
    i = i - 2
  if i == - 1: ret[start] = chr(ord('0') + x)

template addIntImpl*(ret: var string, num: uint64, length: int, start: int) =
  # pending bug #15952, use instead `addIntImpl(result: var openArray[char], num: uint64)`
  when nimvm:
    addIntImpl2(ret, num, length, start)
  else:
    let ret2 = cast[ptr UncheckedArray[char]](result[result.len - length].addr)
    addIntImpl2(ret2, num, length, 0)
