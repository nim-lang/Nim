discard """
  matrix: "--mm:refc; --mm:orc"
"""

# bug #26273: the VM must free strings and seqs; then their memory is reused.

type
  Obj = object
    s: string
    xs: seq[int]

proc distinctPayloads(f: proc (): int {.nimcall.}): int {.compileTime.} =
  var seen: seq[int] = @[]
  for _ in 0 ..< 100:
    let p = f()
    if p notin seen: seen.add p
  result = seen.len

proc viaAddr(): int {.compileTime.} =
  let s = @[newString(1000)]
  discard addr s[0]
  result = cast[int](s[0].cstring)

proc viaFor(): int {.compileTime.} =
  result = 0
  for x in @[newString(1000)]:
    result = cast[int](x.cstring)
    break

proc viaObj(): int {.compileTime.} =
  var o = Obj(s: newString(1000), xs: @[1, 2, 3])
  var p = o
  p.s[0] = 'a'
  result = cast[int](p.s.cstring)

static:
  doAssert distinctPayloads(viaAddr) <= 4
  doAssert distinctPayloads(viaFor) <= 4
  doAssert distinctPayloads(viaObj) <= 4
