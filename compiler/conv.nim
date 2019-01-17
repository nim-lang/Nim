#[
unfinished
generic parser
]#

import parseutils
from strutils import startsWith, continuesWith

template enforce(a: untyped, msg: untyped) =
  # todo: custom catchable exception
  doAssert a, $msg

proc skipWhitespace(src: string, start: var int) =
  while start < src.len and src[start] == ' ': # CHECKME for ws
    start.inc

template skipWhitespace2() = skipWhitespace(src, start)

template continuesWith2(pattern: string): bool=
  src.continuesWith(pattern, start)


template continuesWithAndAdvance(pattern: string): bool=
  let old = start
  skipWhitespace2()
  if src.continuesWith(pattern, start):
    start.inc pattern.len
    true
  else:
    start = old
    false

proc eat(src: string, start: var int, pattern: string) =
  enforce continuesWithAndAdvance(pattern), (src, start, pattern)

template eat2(pattern: string) = eat(src, start, pattern)

proc parseFrom*[T](dst: var T, src: string, start: var int) =
  template process(parseCustom) =
    let ret = parseCustom(src, dst, start)
    enforce ret > 0, (start, src)
    start += ret

  skipWhitespace2()
  when T is seq:
    parseFromList(dst, src, start, "@[", "]")
  elif T is array:
    parseFromList(dst, src, start, "[", "]")
  elif T is tuple:
    parseFromTuple(dst, src, start, "(", ")")
  elif T is int: process(parseInt)
  elif T is float: process(parseFloat)
  elif T is string: parseFromString(dst, src, start)
  elif T is bool:
    if continuesWithAndAdvance("true"): dst = true
    elif continuesWithAndAdvance("false"): dst = false
    else:
      # else: enforce false, ($T, start, src) # nim BUG cgen error
      doAssert false, $($T, start)
  else:
    static: doAssert false, $T

proc parseFromString*(dst: var string, src: string, start: var int) =
  if continuesWithAndAdvance "\"":
    while true:
      if continuesWithAndAdvance "\"": #IMRPOVE: handle correctly \" ; handle other stirng litterals
        break
      else:
        dst.add src[start]
        start.inc

  # const triple = """""""""
  # if continuesWithAndAdvance triple:
  #   while true:
  #     # PRTEMP
  #     # if not endsWith triple:

proc parseFromTuple*(dst: var tuple, src: string, start: var int, left, right: string) =
  eat2(left)
  var done = false
  for k,v in fieldPairs(dst):
    enforce not done, (src, start, k)
    parseFrom(v, src, start)
    if not continuesWithAndAdvance(","):
      done = true
  eat2(right)

type seqLike = seq | array
proc parseFromList*(dst: var seqLike, src: string, start: var int, left, right: string) =
  type T = type(dst[0]) #CHECKME: ok for empty array?
  eat2(left)
  var count = 0
  while true:
    if continuesWithAndAdvance(right): return
    var a: T
    parseFrom(a, src, start)
    when dst is seq:
      dst.add a
    elif dst is array:
      dst[count] = a
      count.inc
    else:
      static: doAssert false
    if continuesWithAndAdvance(","):
      continue
    else:
      break
  eat2(right)

proc parseFrom*[T](dst: var T, src: string) =
  var start = 0
  parseFrom(dst, src, start)
  enforce start == src.len, (start, src.len)

proc parse*[T](src: string): T =
  parseFrom(result, src)

when isMainModule:
  proc runTest[T](a: T) =
    proc toStr(a: T): string =
      when T is string:
        result.addQuoted a #CHECKME: quoteShellCommand?
      else:
        result = $a
    let ret = parse[T](toStr(a))
    doAssert a == ret, $(a, $a, $T)

  runTest 123
  runTest 3.14
  runTest "foo bar"
  runTest @[1,2]
  runTest @[@[1,2], @[3], @[]]
  runTest @[true, false]
  runTest [true, false]
  runTest (true, 12, 3.4, "foo")
  runTest (true, [12.2], (3.4,32,), @[@[10,10],@[]])
