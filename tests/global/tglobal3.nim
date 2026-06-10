discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c cpp"
"""

block: # bug #17552
  proc main: string = 
    var tc {.global.} = "hi"
    tc &= "hi"
    result = tc

  doAssert main() == "hihi"
  doAssert main() == "hihihi"
  doAssert main() == "hihihihi"

# bug #24940
var v: int

proc ccc(): ref int =
  let tmp = new int
  v += 1
  tmp[] = v
  tmp

proc f(v: static string): int =
  let xxx {.global.} = ccc()
  xxx[]

doAssert f("1") == 1
doAssert f("1") == 1

block: # bug #24981
  func p(T: type): T {.compileTime.} = default(ptr T)[]
  type W = ref object
  proc g(T: type): W
  proc m(T: type) =
    let a {.global.} = g(T)
  proc g(T: type): W =
    when T is object:
      m(typeof(p(T).i))
  type Foo = object
    i: int
  m(Foo)

block: # bug #24997
  type R = ref object
  type B = object
    j: int
  proc y(T: type): R
  proc u(T: type): R =
    let res {.global.} = y(T)
    res
  proc y(T: type): R =
    when T is object:
      doAssert not isNil(u(typeof(B.j)))
    R()
  discard u(B)

proc f2(str: string): string = str
proc m2()  =
  let v {.global, used.}: string = f2(f2("123"))
  assert v == "123"

m2()

import mglobal3
block:
  v()