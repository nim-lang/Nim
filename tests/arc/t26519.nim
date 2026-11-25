discard """
  output: '''
true 1
caught 1
caught 2
caught 3
caught 4
caught 5
done 6000 1000
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

block: # a proc that assigns `result` on every path can still be left before
  # the assignment, by a check of the compiler or a call that raises. The
  # caller destroys what it received, so `result` must not hold stack garbage.
  proc dirty(): int {.noinline.} =
    # leaves values on the stack that look like pointers
    var a: array[512, int]
    for i in 0 ..< a.len: a[i] = 0x1000 + i * 16
    for i in 0 ..< a.len: result += a[i]

  proc rangeCheck(n: int): string =
    var small: seq[int] = @[]
    result = $small[n]

  proc concatAfterCheck(n: int): string =
    var small: seq[int] = @[]
    "head" & $small[n]

  proc seqResult(n: int): seq[string] =
    var small: seq[int] = @[]
    result = @[$small[n]]

  type Node = ref object
    name: string

  proc refResult(n: int): Node =
    var small: seq[int] = @[]
    let v = small[n]
    result = Node(name: $v)

  proc raising(n: int): string =
    if n >= 0: raise newException(ValueError, "raised")
    result = "unreachable"

  proc passThrough(n: int): string =
    result = raising(n)

  template attempt(id: int, call: untyped) =
    proc `run id`() =
      try:
        echo call
      except CatchableError, Defect:
        echo "caught ", id
    discard dirty()
    `run id`()

  attempt(1, rangeCheck(7))
  attempt(2, concatAfterCheck(7))
  attempt(3, seqResult(7))
  attempt(4, refResult(7).name)
  attempt(5, passThrough(1))

  # the heap is intact afterwards
  var t = ""
  for i in 0 ..< 3000: t.add("x" & $(i mod 10))
  var s: seq[string]
  for i in 0 ..< 1000: s.add $i
  echo "done ", t.len, " ", s.len
