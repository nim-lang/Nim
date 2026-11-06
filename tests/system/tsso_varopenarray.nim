discard """
  matrix: "--strings:sso --mm:orc; --strings:sso --mm:orc -d:release; --mm:orc; --mm:refc"
  targets: "c cpp"
  output: "true"
"""

# #26613 follow-up: writes to a long string through `var openArray[char]`
# parameters and through `mitems`/`mpairs` must keep `==`/`cmp` working
# under `--strings:sso` (the inline prefix is resynced after them)
import std/[os, strutils]

var ok = true
template check(cond: bool) =
  if not cond:
    ok = false
    echo "failed: ", astToStr(cond)

proc fill(x: var openArray[char]; c: char) =
  for i in 0..<x.len: x[i] = c

proc fillCount(x: var openArray[char]; c: char): int =
  fill(x, c)
  result = x.len

proc fillRaise(x: var openArray[char]) =
  fill(x, 'r')
  raise newException(ValueError, "after write")

proc id(x: int): int = x

for L in [0, 1, 7, 8, 14, 15, 16, 30, 100]:
  let want = repeat('x', L)

  var a = repeat('a', L)
  fill(a, 'x')
  check a == want
  check cmp(a, want) == 0

  var b = repeat('a', L)
  check fillCount(b, 'x') + id(1) == L + 1 # call result used in an expression
  check b == want

  var c = repeat('a', L)
  if L > 0:
    fill(toOpenArray(c, 0, L-1), 'x')
  check c == want

  var d = repeat('a', L)
  for ch in d.mitems: ch = 'x'
  check d == want

  var e = repeat('a', L)
  for i, ch in e.mpairs: ch = 'x'
  check e == want

  var f = repeat('a', L)
  for ch in f.mitems:
    ch = 'x'
    break # leaves the loop after the first write
  if L > 0:
    check f == "x" & repeat('a', L-1)

  when not defined(cpp):
    # with goto exceptions the resync also runs when the callee raises
    var g = repeat('a', L)
    try:
      fillRaise(g)
    except ValueError:
      discard
    check g == repeat('r', L)

  var h = repeat('a', L)
  fill(h, char(ord('a') + fillCount(toOpenArray(h, 0, L-1), 'q') mod 1)) # nested
  check h == repeat('a', L)

# a long string literal is copied before it is written
var lit = "a long string literal that is shared"
fill(lit, 'x')
check lit == repeat('x', 36)

let fn = getTempDir() / "tsso_varopenarray.txt"
writeFile(fn, "a file with more than fifteen chars")
var buf = newString(35)
let fh = open(fn)
check readChars(fh, buf) == 35
fh.close()
removeFile(fn)
check buf == "a file with more than fifteen chars"

static:
  var s = repeat('a', 20)
  for ch in s.mitems: ch = 'x'
  doAssert s == repeat('x', 20)
  var t = repeat('a', 20)
  fill(t, 'x')
  doAssert t == repeat('x', 20)

echo ok
