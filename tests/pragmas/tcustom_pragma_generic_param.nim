discard """
  output: '''
2
5
(v: 3, name: "x")
7
4
9
5
int16
2
'''
"""

# the value of a custom pragma of a field can refer to the generic params of
# the object type, the compiler instantiates the pragmas with the type

import std/macros

template tag(v: int) {.pragma.}
template pair(v: int, name: string) {.pragma.}

type
  R[N: static int] = object
    field {.tag(N).}: int

var r: R[2]
echo r.field.getCustomPragmaVal(tag)

type
  Base[T; M: static int] = object of RootObj
    b {.tag(M).}: T
  D[K: static int] = object of Base[string, K]

var d: D[5]
echo d.b.getCustomPragmaVal(tag)

type P[A: static int; S: static string] = object
  f {.pair(A, S).}: int

var p: P[3, "x"]
echo p.f.getCustomPragmaVal(pair)

type
  Alias = R[7]
  RefR[N: static int] = ref object
    g {.tag(N).}: int

var a: Alias
echo a.field.getCustomPragmaVal(tag)

let rr = RefR[4]()
echo rr.g.getCustomPragmaVal(tag)

proc inGeneric[N: static int](x: R[N]): int = x.field.getCustomPragmaVal(tag)
echo inGeneric(R[9]())

doAssert r.field.hasCustomPragma(tag)

template ty(t: typedesc) {.pragma.}
type G[T; N: static int] = object
  a {.tag(N + 1).}: int
  b {.ty(T).}: int
  c {.tag(sizeof(T)).}: int

var g: G[int16, 4]
echo g.a.getCustomPragmaVal(tag)
var x: g.b.getCustomPragmaVal(ty) = 3
echo typeof(x)
echo g.c.getCustomPragmaVal(tag)
