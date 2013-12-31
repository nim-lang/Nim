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
  vnotbaz: TFoo[TObject, TObject]

proc foo(x: TFoo) = echo "foo"
proc bar(x: TBar) = echo "bar"
proc baz(x: TBaz) = echo "baz"

accept foo(vfoo)
accept bar(vbar)
accept baz(vbar)
accept baz(vbaz)

reject baz(vnotbaz)
reject bar(vfoo)

# https://github.com/Araq/Nimrod/issues/517
type
  TVecT*[T] = array[0..1, T]|array[0..2, T]|array[0..3, T]
  TVec2* = array[0..1, float32]

proc f[T](a: TVecT[T], b: TVecT[T]): T = discard

var x: float = f([0.0'f32, 0.0'f32], [0.0'f32, 0.0'f32])
var y = f(TVec2([0.0'f32, 0.0'f32]), TVec2([0.0'f32, 0.0'f32]))

