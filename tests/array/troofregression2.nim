discard """
  output: '''OK
OK
OK
OK
OK
dflfdjkl__abcdefgasfsgdfgsgdfggsdfasdfsafewfkljdsfajs
dflfdjkl__abcdefgasfsgdfgsgdfggsdfasdfsafewfkljdsfajsdf
kgdchlfniambejop
fjpmholcibdgeakn
'''
"""

import strutils, sequtils, typetraits, os
# bug #6989

type Dist = distinct int

proc mypred[T: Ordinal](x: T): T = T(int(x)-1)
proc cons(x: int): Dist = Dist(x)

var d: Dist

template `^+`(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))

proc `...`*[T, U](a: T, b: U): HSlice[T, U] =
  result.a = a
  result.b = b

proc `...`*[T](b: T): HSlice[int, T] =
  result.b = b

template `...<`*(a, b: untyped): untyped =
  ## a shortcut for 'a..pred(b)'.
  a ... pred(b)

template check(a, b) =
  if $a == b: echo "OK"
  else: echo "Failure ", a, " != ", b

check type(4 ...< 1), "HSlice[system.int, system.int]"

check type(4 ...< ^1), "HSlice[system.int, system.BackwardsIndex]"
check type(4 ... pred(^1)), "HSlice[system.int, system.BackwardsIndex]"

check type(4 ... mypred(8)), "HSlice[system.int, system.int]"

check type(4 ... mypred(^1)), "HSlice[system.int, system.BackwardsIndex]"

var rot = 8

proc bug(s: string): string =
  result = s
  result = result[result.len - rot .. ^1] & "__" & result[0 ..< ^rot]

const testStr = "abcdefgasfsgdfgsgdfggsdfasdfsafewfkljdsfajsdflfdjkl"

echo bug(testStr)
echo testStr[testStr.len - 8 .. testStr.len - 1] & "__" & testStr[0 .. testStr.len - pred(rot)]



var
  instructions = readFile(getAppDir() / "troofregression2.txt").split(',')
  programs = "abcdefghijklmnop"

proc dance(dancers: string): string =
  result = dancers
  for instr in instructions:
    let rem = instr[1 .. instr.high]
    case instr[0]
    of 's':
      let rot = rem.parseInt
      result = result[result.len - rot .. ^1] & result[0 ..< ^rot]
    of 'x':
      let
        x = rem.split('/')
        a = x[0].parseInt
        b = x[1].parseInt
      swap(result[a], result[b])
    of 'p':
      let
        a = result.find(rem[0])
        b = result.find(rem[^1])
      result[a] = rem[^1]
      result[b] = rem[0]
    else: discard

proc longDance(dancers: string, iterations = 1_000_000_000): string =
  var
    dancers = dancers
    seen = @[dancers]
  for i in 1 .. iterations:
    dancers = dancers.dance()
    if dancers in seen:
      return seen[iterations mod i]
    seen.add(dancers)


echo dance(programs)
echo longDance(programs)
