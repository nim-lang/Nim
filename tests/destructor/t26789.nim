discard """
  matrix: "--mm:orc -d:useMalloc; --mm:arc -d:useMalloc; --mm:orc -d:useMalloc -d:release; --mm:refc"
  valgrind: "true"
  output: '''
1 2
abcd
done
'''
"""

# bug #26789: a routine returning `lent T` whose body is an `if` or `case`
# expression returned a view of a temporary copy, destroyed before returning

func f(a: seq[int]): lent seq[int] =
  if true: a else: a

func g(a: seq[int], k: bool): lent seq[int] =
  case k
  of true: a
  of false: a

type
  Kind = enum kA, kB, kC
  O = object
    x, y, z: seq[byte]

func field(o: O, k: Kind): lent seq[byte] =
  case k
  of kA: o.x
  of kB: o.y
  of kC: o.z

func nested(o: O, k: Kind, b: bool): lent seq[byte] =
  if b:
    case k
    of kA: o.x
    else: o.y
  else:
    discard "a statement before the value"
    o.z

func viaReturn(o: O, first: bool): lent seq[byte] =
  return if first: o.x else: o.y

func str(s: string, b: bool): lent string =
  if b: s else: s

proc main() =
  let a = @[1, 2]
  doAssert f(a)[0].addr == a[0].addr
  doAssert g(a, true)[0].addr == a[0].addr
  doAssert g(a, false)[0].addr == a[0].addr
  echo f(a)[0], " ", g(a, false)[1]

  let o = O(x: @[1'u8], y: @[2'u8], z: @[3'u8])
  doAssert field(o, kA)[0].addr == o.x[0].addr
  doAssert field(o, kB)[0].addr == o.y[0].addr
  doAssert field(o, kC)[0].addr == o.z[0].addr
  doAssert nested(o, kA, true)[0].addr == o.x[0].addr
  doAssert nested(o, kC, true)[0].addr == o.y[0].addr
  doAssert nested(o, kA, false)[0].addr == o.z[0].addr
  doAssert viaReturn(o, true)[0].addr == o.x[0].addr
  doAssert viaReturn(o, false)[0].addr == o.y[0].addr

  var s = "ab"
  s.add "cd"
  doAssert str(s, true)[0].addr == s[0].addr
  echo str(s, false)
  echo "done"

main()
