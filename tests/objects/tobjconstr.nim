discard """
  output: '''
(k: kindA, a: (x: "abc", z: @[1, 1, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 2, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 3, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 4, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 5, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 6, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 7, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 8, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 9, 3]), method: ())
(k: kindA, a: (x: "abc", z: @[1, 10, 3]), method: ())
(y: 0, x: 123)
(y: 678, x: 123)
(z: 89, y: 0, x: 128)
(y: 678, x: 123)
(y: 678, x: 123)
(y: 0, x: 123)
(y: 678, x: 123)
(y: 123, x: 678)
'''
"""

type
  TArg = object
    x: string
    z: seq[int]
  TKind = enum kindXY, kindA
  TEmpty = object
  TDummy = ref object
    case k: TKind
    of kindXY: x, y: int
    of kindA:
      a: TArg
      `method`: TEmpty # bug #1791

proc main() =
  for i in 1..10:
    let d = TDummy(k: kindA, a: TArg(x: "abc", z: @[1,i,3]), `method`: TEmpty())
    echo d[]

main()

# bug #6294
type
  A = object of RootObj
    x*: int
  B = object of A
    y*: int
  BS = object of B
  C = object of BS
    z*: int
# inherited fields are ignored, so no fields are set
when true:
  var
    o: B
  o = B(x: 123)
  echo o
  o = B(y: 678, x: 123)
  echo o

# inherited fields are ignored
echo C(x: 128, z: 89)          # (y: 0, x: 0)
echo B(y: 678, x: 123)  # (y: 678, x: 0)
echo B(x: 123, y: 678)  # (y: 678, x: 0)

when true:
  # correct, both with `var` and `let`;
  var b=B(x: 123)
  echo b                  # (y: 0, x: 123)
  b=B(y: 678, x: 123)
  echo b                  # (y: 678, x: 123)
  b=B(y: b.x, x: b.y)
  echo b                  # (y: 123, x: 678)

GC_fullCollect()
