discard """
  output: '''ok
ok
ok'''
"""

# bug #25693

proc d() = discard @[0]

proc f(a: var seq[int], _: string) =
  let p = @[0]
  d()
  a = p

block: # scalar `untyped` parameter
  template g(b: untyped) {.dirty.} =
    template t: untyped = b

  proc g(_: int) = discard

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

block: # `typed` parameter captured and re-emitted: each emission gets its own
       # symbols, otherwise the destructor/liveness pass miscompiles the shared
       # local `a` and the program crashes at runtime
  template g(b: typed) {.dirty.} =
    template t: untyped = b

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

block: # `varargs[untyped]` parameter takes the same pristine-AST path
  template g(b: varargs[untyped]) {.dirty.} =
    template t: untyped = b

  proc g(_: int) = discard

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
