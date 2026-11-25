discard """
  output: '''
GA(a: 3)
3
GA(a: "x")
x
FA(x: 3)
(k: true, a: 4)
(k: true, a: 5)
'''
"""

# sum types and case objects declared in generic procs and templates

proc g[T](v: T) =
  type G = object
    case
    of GA: a: T
    of GB: discard
  echo GA(a: v)
  case GA(a: v)
  of GA(a): echo a
  of GB: discard
g(3)
g("x")

template defSum() =
  type Foo = object
    case
    of FA: x: int
    of FB: y: string
defSum()
echo FA(x: 3)

template defCase() =
  type Bar = object
    case k: bool
    of true: a: int
    of false: discard
  echo Bar(k: true, a: 4)
defCase()

proc h[T](v: T) =
  type Baz = object
    case k: bool
    of true: a: T
    of false: discard
  echo Baz(k: true, a: v)
h(5)
