type MyObject = object
  x, y: int
  s: string

const c = @[MyObject(x: 1, y: 2, s: "")]

type Foo[A, B; C: static seq[MyObject]] = object
  s: string
  f: typeof(C)

proc build*[A; B; C: static seq[MyObject]](s: string;): Foo[A, B, C] =
  const d = C
  doAssert d[0].x == c[0].x
  doAssert d[0].x == 1
  result.f = d
  result.s = s

proc build*[A; B; C: static seq[MyObject]](): Foo[A, B, C] =
  build[A, B, C]("foo")

type
  Bar = object
  Baz = object

let r = build[Bar, Baz, c]()
doAssert r.s == "foo"
doAssert r.f == c
