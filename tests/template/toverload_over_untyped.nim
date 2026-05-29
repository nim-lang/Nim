discard """
  output: "ok"
"""

# bug #25693

template g(b: untyped) {.dirty.} =
  template t: untyped = b

proc d() = discard @[0]
proc g(_: int) = discard

proc f(a: var seq[int], _: string) =
  let p = @[0]
  d()
  a = p

let q = "a"
g:
  var a: seq[int]
  try:
    f(a, q & "1")
  except CatchableError:
    discard
  try:
    f(a, q & "1")
  except CatchableError:
    discard
block: t()
block: t()
echo "ok"

