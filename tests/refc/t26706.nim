discard """
  matrix: "--mm:refc"
  output: "1"
"""

# bug #26706: closure iterator `var x: Obj` in a loop never released its refs

type
  Obj = object
    r: ref int

proc getRefcount(p: pointer): int {.importc: "getRefcount".}

let shared = new int

iterator it(): int {.closure.} =
  for i in 0 ..< 1000:
    var x: Obj
    x.r = shared
    yield i

let base = getRefcount(cast[pointer](shared))
let iter = it
for i in iter():
  if i == 999:
    echo getRefcount(cast[pointer](shared)) - base
