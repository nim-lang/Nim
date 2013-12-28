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

