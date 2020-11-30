const digitsTable* = "0001020304050607080910111213141516171819" &
    "2021222324252627282930313233343536373839" &
    "4041424344454647484950515253545556575859" &
    "6061626364656667686970717273747576777879" &
    "8081828384858687888990919293949596979899"

func digits10*(num: uint64): int {.noinline.} =
  if num < 10:
    result = 1
  elif num < 100:
    result = 2
  elif num < 1_000:
    result = 3
  elif num < 10_000:
    result = 4
  elif num < 100_000:
    result = 5
  elif num < 1_000_000:
    result = 6
  elif num < 10_000_000:
    result = 7
  elif num < 100_000_000:
    result = 8
  elif num < 1_000_000_000:
    result = 9
  elif num < 10_000_000_000'u64:
    result = 10
  elif num < 100_000_000_000'u64:
    result = 11
  elif num < 1_000_000_000_000'u64:
    result = 12
  else:
    result = 12 + digits10(num div 1_000_000_000_000'u64)

template numToString*(result: var string, origin: uint64, length: int) =
  var num = origin
  var next = length - 1
  while num >= 100:
    let originNum = num
    num = num div 100
    let index = (originNum - num * 100) shl 1
    result[next] = digitsTable[index + 1]
    result[next - 1] = digitsTable[index]
    dec(next, 2)

  # process last 1-2 digits
  if num < 10:
    result[next] = chr(ord('0') + num)
  else:
    let index = num * 2
    result[next] = digitsTable[index + 1]
    result[next - 1] = digitsTable[index]
