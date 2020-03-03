discard """
  output: '''10
10
10
3
3
noReturn
6
calling mystuff
yes
calling mystuff
yes
'''
"""

import future, macros

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

echo twoParams(proc (a, b: auto): auto = a + b)
echo twoParams((x, y) => x + y)

echo oneParam(x => x+5)

echo noParams(() => 3)

echo doWithOneAndTwo((x, y) => x + y)

noReturn((() -> void) => echo("noReturn"))

proc pass2(f: (int, int) -> int): (int) -> int =
  ((x: int) -> int) => f(2, x)

echo pass2((x, y) => x + y)(4)



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
