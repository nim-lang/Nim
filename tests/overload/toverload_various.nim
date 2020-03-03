discard """
  output: '''
true012innertrue
m1
tup1
another number: 123
yay
helloa 1 b 2 x @[3, 4, 5] y 6 z 7
yay
12
ref ref T ptr S
dynamic: let
dynamic: var
static: const
static: literal
static: constant folding
static: static string
foo1
1
'''
"""


import strutils, sequtils


block overl2:
  # Test new overloading resolution rules
  proc toverl2(x: int): string = return $x
  proc toverl2(x: bool): string = return $x

  iterator toverl2(x: int): int =
    var res = 0
    while res < x:
      yield res
      inc(res)

  var
    pp: proc (x: bool): string {.nimcall.} = toverl2

  stdout.write(pp(true))

  for x in toverl2(3):
    stdout.write(toverl2(x))

  block:
    proc toverl2(x: int): string = return "inner"
    stdout.write(toverl2(5))
    stdout.write(true)

  stdout.write("\n")
  #OUT true012innertrue



block overl3:
  # Tests more specific generic match:
  proc m[T](x: T) = echo "m2"
  proc m[T](x: var ref T) = echo "m1"
  proc tup[S, T](x: tuple[a: S, b: ref T]) = echo "tup1"
  proc tup[S, T](x: tuple[a: S, b: T]) = echo "tup2"

  var
    obj: ref int
    tu: tuple[a: int, b: ref bool]

  m(obj)
  tup(tu)



block toverprc:
  # Test overloading of procs when used as function pointers
  proc parseInt(x: float): int {.noSideEffect.} = discard
  proc parseInt(x: bool): int {.noSideEffect.} = discard
  proc parseInt(x: float32): int {.noSideEffect.} = discard
  proc parseInt(x: int8): int {.noSideEffect.} = discard
  proc parseInt(x: File): int {.noSideEffect.} = discard
  proc parseInt(x: char): int {.noSideEffect.} = discard
  proc parseInt(x: int16): int {.noSideEffect.} = discard

  proc parseInt[T](x: T): int = echo x; 34

  type
    TParseInt = proc (x: string): int {.noSideEffect.}

  var
    q = TParseInt(parseInt)
    p: TParseInt = parseInt

  proc takeParseInt(x: proc (y: string): int {.noSideEffect.}): int =
    result = x("123")

  if false:
    echo "Give a list of numbers (separated by spaces): "
    var x = stdin.readline.split.map(parseInt).max
    echo x, " is the maximum!"
  echo "another number: ", takeParseInt(parseInt)


  type
    TFoo[a,b] = object
      lorem: a
      ipsum: b

  proc bar[a,b](f: TFoo[a,b], x: a) = echo(x, " ", f.lorem, f.ipsum)
  proc bar[a,b](f: TFoo[a,b], x: b) = echo(x, " ", f.lorem, f.ipsum)

  discard parseInt[string]("yay")



block toverwr:
  # Test the overloading resolution in connection with a qualifier
  proc write(t: File, s: string) =
    discard # a nop
  system.write(stdout, "hello")
  #OUT hello



block tparams_after_varargs:
  proc test(a, b: int, x: varargs[int]; y, z: int) =
    echo "a ", a, " b ", b, " x ", @x, " y ", y, " z ", z

  test 1, 2, 3, 4, 5, 6, 7

  # XXX maybe this should also work with ``varargs[untyped]``
  template takesBlockA(a, b: untyped; x: varargs[typed]; blck: untyped): untyped =
    blck
    echo a, b

  takesBlockA 1, 2, "some", 0.90, "random stuff":
    echo "yay"



block tprefer_specialized_generic:
  proc foo[T](x: T) =
    echo "only T"

  proc foo[T](x: ref T) =
    echo "ref T"

  proc foo[T, S](x: ref ref T; y: ptr S) =
    echo "ref ref T ptr S"

  proc foo[T, S](x: ref T; y: ptr S) =
    echo "ref T ptr S"

  proc foo[T](x: ref T; default = 0) =
    echo "ref T; default"

  var x: ref ref int
  var y: ptr ptr int
  foo(x, y)



block tstaticoverload:
  proc foo(s: string) =
    echo "dynamic: ", s

  proc foo(s: static[string]) =
    echo "static: ", s

  let l = "let"
  var v = "var"
  const c = "const"

  type staticString = static[string]

  foo(l)
  foo(v)
  foo(c)
  foo("literal")
  foo("constant" & " " & "folding")
  foo(staticString("static string"))

# bug #8568 (2)

proc goo(a: int): string = "int"
proc goo(a: static[int]): string = "static int"
proc goo(a: var int): string = "var int"
proc goo[T: int](a: T): string = "T: int"
#proc goo[T](a: T): string = "nur T"

const tmp1 = 1
let tmp2 = 1
var tmp3 = 1

doAssert goo(1) == "static int"
doAssert goo(tmp1) == "static int"
doAssert goo(tmp2) == "int"
doAssert goo(tmp3) == "var int"

doAssert goo[int](1) == "T: int"

doAssert goo[int](tmp1) == "T: int"
doAssert goo[int](tmp2) == "T: int"
doAssert goo[int](tmp3) == "T: int"

# bug #6076

type A[T] = object

proc regr(a: A[void]) = echo "foo1"
proc regr[T](a: A[T]) = doAssert(false)

regr(A[void]())


type Foo[T] = object

proc regr[T](p: Foo[T]): seq[T] =
  discard

proc regr(p: Foo[void]): seq[int] =
  discard


discard regr(Foo[int]())
discard regr(Foo[void]())


type
  Sha2Context*[bits: static[int],
               bsize: static[int],
               T: uint32|uint64] = object
    count: array[2, T]
    state: array[8, T]
    buffer: array[bsize, byte]

  sha224* = Sha2Context[224, 64, uint32]
  sha256* = Sha2Context[256, 64, uint32]
  sha384* = Sha2Context[384, 128, uint64]
  sha512* = Sha2Context[512, 128, uint64]
  sha512_224* = Sha2Context[224, 128, uint64]
  sha512_256* = Sha2Context[256, 128, uint64]

type
  RipemdContext*[bits: static[int]] = object
    count: array[2, uint32]
    state: array[bits div 32, uint32]
    buffer: array[64, byte]

  ripemd128* = RipemdContext[128]
  ripemd160* = RipemdContext[160]
  ripemd256* = RipemdContext[256]
  ripemd320* = RipemdContext[320]

const
  MaxHmacBlockSize = 256

type
  HMAC*[HashType] = object
    mdctx: HashType
    opadctx: HashType

template sizeBlock*(h: HMAC[Sha2Context]): uint = 1u
template sizeBlock*(h: HMAC[RipemdContext]): uint = 0u

proc init*[T](hmctx: HMAC[T], key: ptr byte, ulen: uint) =
  const sizeBlock = hmctx.sizeBlock
  echo sizeBlock

proc hmac*[A, B](HashType: typedesc, key: openarray[A],
                 data: openarray[B]) =
  var ctx: HMAC[HashType]
  ctx.init(nil, 0)

sha256.hmac("", "")
