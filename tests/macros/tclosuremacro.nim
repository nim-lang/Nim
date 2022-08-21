discard """
  output: '''
noReturn
calling mystuff
yes
calling mystuff
yes
'''
"""

import sugar, macros

proc twoParams(x: (int, int) -> int): int =
  result = x(5, 5)

proc oneParam(x: int -> int): int =
  x(5)

proc noParams(x: () -> int): int =
  result = x()

proc noReturn(x: () -> void) =
  x()

proc doWithOneAndTwo(f: (int, int) -> int): int =
  f(1,2)

doAssert twoParams(proc (a, b: auto): auto = a + b) == 10
doAssert twoParams((x, y) => x + y) == 10
doAssert oneParam(x => x+5) == 10
doAssert noParams(() => 3) == 3
doAssert doWithOneAndTwo((x, y) => x + y) == 3

noReturn((() -> void) => echo("noReturn"))

proc pass2(f: (int, int) -> int): (int) -> int =
  ((x: int) -> int) => f(2, x)

doAssert pass2((x, y) => x + y)(4) == 6

const fun = (x, y: int) {.noSideEffect.} => x + y

doAssert typeof(fun) is (proc (x, y: int): int {.nimcall.})
doAssert fun(3, 4) == 7

proc register(name: string; x: proc()) =
  echo "calling ", name
  x()

register("mystuff", proc () =
  echo "yes"
)

proc helper(x: NimNode): NimNode =
  if x.kind == nnkProcDef:
    result = copyNimTree(x)
    result[0] = newEmptyNode()
    result = newCall("register", newLit($x[0]), result)
  else:
    result = copyNimNode(x)
    for i in 0..<x.len:
      result.add helper(x[i])

macro m(x: untyped): untyped =
  result = helper(x)

m:
  proc mystuff() =
    echo "yes"

const typedParamAndPragma = (x, y: int) -> int => x + y
doAssert typedParamAndPragma(1, 2) == 3

type
  Bot = object
    call: proc (): string {.noSideEffect.}

var myBot = Bot()
myBot.call = () {.noSideEffect.} => "I'm a bot."
doAssert myBot.call() == "I'm a bot."
