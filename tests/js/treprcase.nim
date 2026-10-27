discard """
  output: '''
[k = kSome,
val = 42]
[k = kNone]
Rect[x = 1,
w = 2,
h = 3]
[k = 2,
e = "else"]
'''
"""

# repr of case objects and sum types on the JS backend
type
  K = enum kNone, kSome
  Opt = object
    case k: K
    of kNone: discard
    of kSome: val: int
  Sum = object
    x: int
    case
    of Circle: r: float
    of Rect: w, h: int
  E = object
    case k: range[0..3]
    of 0: z: int
    else: e: string
echo repr(Opt(k: kSome, val: 42))
echo repr(Opt(k: kNone))
echo repr(Rect(x: 1, w: 2, h: 3))
echo repr(E(k: 2, e: "else"))
