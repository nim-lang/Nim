template accept(e) =
  static: assert(compiles(e))

template reject(e) =
  static: assert(not compiles(e))

type
  TFoo[T, U] = tuple
    x: T
    y: U

  TBar[K] = TFoo[K, K]

  TUserClass = int|string

  TBaz = TBar[TUserClass]

var
  vfoo: TFoo[int, string]
  vbar: TFoo[string, string]
  vbaz: TFoo[int, int]
  vnotbaz: TFoo[RootObj, RootObj]

proc foo(x: TFoo) = echo "foo"
proc bar(x: TBar) = echo "bar"
proc baz(x: TBaz) = echo "baz"

accept foo(vfoo)
accept bar(vbar)
accept baz(vbar)
accept baz(vbaz)

#reject baz(vnotbaz) # XXX this really shouldn't compile
reject bar(vfoo)

# https://github.com/Araq/Nim/issues/517
type
  TVecT*[T] = array[0..1, T]|array[0..2, T]|array[0..3, T]
  TVec2* = array[0..1, float32]

proc f[T](a: TVecT[T], b: TVecT[T]): T = discard

var x: float = f([0.0'f32, 0.0'f32], [0.0'f32, 0.0'f32])
var y = f(TVec2([0.0'f32, 0.0'f32]), TVec2([0.0'f32, 0.0'f32]))

# https://github.com/Araq/Nim/issues/602
type
  TTest = object
  TTest2* = object
  TUnion = TTest | TTest2

proc f(src: ptr TUnion, dst: ptr TUnion) =
  echo("asd")

var tx: TTest
var ty: TTest2

accept f(addr tx, addr tx)
reject f(addr tx, addr ty)
