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
  buf[pos] = digits100[2 * digits]
  buf[pos+1] = digits100[2 * digits + 1]
  #copyMem(buf, unsafeAddr(digits100[2 * digits]), 2 * sizeof((char)))

proc trailingZeros2Digits*(digits: uint32): int32 {.inline.} =
  return trailingZeros100[digits]

when defined(js):
  proc numToString(a: SomeInteger): cstring {.importjs: "((#) + \"\")".}

func addChars[T](result: var string, x: T, start: int, n: int) {.inline.} =
  let old = result.len
  result.setLen old + n
  template impl =
    for i in 0..<n: result[old + i] = x[start + i]
  when nimvm: impl
  else:
    when defined(js) or defined(nimscript): impl
    else:
      {.noSideEffect.}:
        copyMem result[old].addr, x[start].unsafeAddr, n

func addChars[T](result: var string, x: T) {.inline.} =
  addChars(result, x, 0, x.len)

func addIntImpl(result: var string, x: uint64) {.inline.} =
  var tmp {.noinit.}: array[24, char]
  var num = x
  var next = tmp.len - 1
  const nbatch = 100

  while num >= nbatch:
    let originNum = num
    num = num div nbatch
    let index = (originNum - num * nbatch) shl 1
    tmp[next] = digits100[index + 1]
    tmp[next - 1] = digits100[index]
    dec(next, 2)

  # process last 1-2 digits
  if num < 10:
    tmp[next] = chr(ord('0') + num)
  else:
    let index = num * 2
    tmp[next] = digits100[index + 1]
    tmp[next - 1] = digits100[index]
    dec next
  addChars(result, tmp, next, tmp.len - next)

func addInt*(result: var string, x: uint64) =
  when nimvm: addIntImpl(result, x)
  else:
    when not defined(js): addIntImpl(result, x)
    else:
      addChars(result, numToString(x))

proc addInt*(result: var string; x: int64) =
  ## Converts integer to its string representation and appends it to `result`.
  runnableExamples:
    var s = "foo"
    s.addInt(45)
    assert s == "foo45"
  template impl =
    var num: uint64
    if x < 0:
      if x == low(int64):
        num = uint64(x)
      else:
        num = uint64(-x)
      let base = result.len
      setLen(result, base + 1)
      result[base] = '-'
    else:
      num = uint64(x)
    addInt(result, num)
  when nimvm: impl()
  else:
    when defined(js):
      addChars(result, numToString(x))
    else: impl()

proc addInt*(result: var string; x: int) {.inline.} =
  addInt(result, int64(x))
