discard """
  output: '''
true 1
'''
  matrix: "--mm:orc -d:useMalloc; --mm:arc -d:useMalloc"
  valgrind: "true"
"""

# bug #26519: `=wasMoved` resets the branch that its reset discriminator
# selects. That branch's bytes are left over from the old branch, so its
# nested discriminators must be reset before they are read.

type
  H = object
    case n: bool
    of true:
      s: string
    of false:
      x: int
      case o: bool
      of false, true: val: int

  W = object
    case n: bool
    of true:
      b: seq[H]
    of false:
      y: H

  G = object
    r: W

proc f(s: string): string =
  if s.len > 0: raise (ref CatchableError)()
  ""

proc d(val: var G) =
  var v: seq[H]
  for _ in 0..0:
    v.add H(n: true, s: f(""))
  val = G(r: W(n: true, b: v))

proc c() {.noinline.} =
  var a {.volatile.}: array[64, byte]
  for i in 0..63: a[i] = 255

proc m(): G =
  c()
  d(result)

let g = m()
echo g.r.n, " ", g.r.b.len
