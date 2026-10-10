discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
7 8 9
ok
'''
"""

# values bigger than the VM's register frames are held by address

type
  Big = object
    a: array[200_000, byte]
    b: array[200_000, byte]
    s: string
    n: int
  Res = object
    ok: bool
    v: Big

proc mk(x: byte): Big =
  result.a[1] = x
  result.b[199_999] = x + 1
  result.s = "big" & $x
  result.n = x.int

proc wrap(b: Big): Res = Res(ok: true, v: b)

proc sumIt(b: Big): int = b.a[1].int + b.b[199_999].int + b.n

proc bump(b: var Big) =
  inc b.a[1]
  b.s.add "!"

proc consume(b: sink Big): string = b.s

proc maybeRaise(b: Big; doRaise: bool): Big =
  if doRaise: raise newException(ValueError, "boom")
  result = b

proc pair(): (Big, Big) = (mk(1), mk(2))

proc arr(): array[2, Big] = [mk(3), mk(4)]

proc loop(): int =
  for i in 0..<20:
    let b = mk(byte(i))
    result += sumIt(b)

proc test(): string =
  var x = mk(5)
  doAssert sumIt(x) == 5 + 6 + 5
  var y = x                      # a copy, not an alias
  bump(y)
  doAssert x.a[1] == 5 and y.a[1] == 6
  doAssert x.s == "big5" and y.s == "big5!"
  let r = wrap(x)
  doAssert r.ok and r.v.n == 5 and r.v.s == "big5"
  doAssert consume(mk(9)) == "big9"
  var caught = false
  try:
    discard maybeRaise(x, true)
  except ValueError:
    caught = true
  doAssert caught
  doAssert maybeRaise(x, false).s == "big5"
  let (p, q) = pair()
  doAssert p.n == 1 and q.n == 2
  let a = arr()
  doAssert a[0].n == 3 and a[1].s == "big4"
  var d = default(Big)
  doAssert d.n == 0 and d.s.len == 0
  d = x
  doAssert d.s == "big5"
  doAssert loop() == (block:
    var s = 0
    for i in 0..<20: s += i + (i+1) + i
    s)
  result = $mk(7).n & " " & $mk(7).b[199_999] & " " & $(sumIt(mk(3)) - 1)

const r = test()
static: doAssert r == "7 8 9"
echo r
const c = mk(11)
static: doAssert c.s == "big11" and c.b[199_999] == 12
echo "ok"
