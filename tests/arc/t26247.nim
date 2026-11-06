discard """
  matrix: "--mm:arc; --mm:orc"
  output: '''
false
true
@[1, 3, 1, 3, 1, 3, 1, 3]
'''
"""

# bug #26247: the closure env was moved into the first closure while still live
type
  State = ref object
    selected: bool
  W = ref object
    a: proc()

proc build(s: State): W =
  result = W()
  if s.selected:
    result.a = proc() = discard s.selected
  else:
    result.a = proc() = discard s.selected
    echo s.selected

proc build2(s: State): W =
  result = W()
  if not s.selected:
    result.a = proc() = discard s.selected
  else:
    result.a = proc() = echo s.selected
  result.a()
  discard s.selected

discard build(State(selected: false))
discard build(State(selected: true))
discard build2(State(selected: true))

# A closure that names a variable declared in a nested scope of the module:
# that variable is a global, there is no environment to keep it alive, so it
# must not be destroyed when its scope ends.

block expression:
  type Hook = proc(layer: int, x: seq[float64]): seq[float64] {.closure.}

  proc runModel(x: seq[float64], hook: Hook): seq[float64] =
    result = x
    for layer in 0 ..< 4:
      discard hook(layer, result)

  var seen: seq[int]
  discard runModel(@[1.0, 2.0], hook = block:
    let layers = @[1, 3]
    let hook: Hook = proc(layer: int, x: seq[float64]): seq[float64] =
      for l in layers: seen.add l
      @[]
    hook)
  echo seen

block lifetimes:
  var live = 0
  type R = object
    v: int
  proc `=destroy`(x: R) = (if x.v != 0: dec live)
  proc `=copy`(a: var R, b: R) {.error.}
  proc `=sink`(a: var R, b: R) =
    if a.v != 0: dec live
    a.v = b.v
  proc mk(v: int): R =
    inc live
    R(v: v)

  var procs: seq[proc(): int]

  block withoutRoutine:
    let a = mk(1)
    doAssert a.v == 1 and live == 1
  doAssert live == 0, "a variable no routine names is destroyed with its scope"

  block withNamedProc:
    let r = mk(9)
    proc named(): int = r.v
    procs.add named
  doAssert live == 1
  doAssert procs[0]() == 9

  block withLambda:
    let r = mk(7)
    procs.add proc(): int = r.v
  doAssert live == 2
  doAssert procs[1]() == 7

  block withNestedLambda:
    let r = mk(5)
    proc outer(): proc(): int =
      result = proc(): int = r.v
    procs.add outer()
  doAssert live == 3
  doAssert procs[2]() == 5

  # one location is shared by the rounds of a loop; the value of an earlier
  # round is destroyed, not leaked
  for i in 1 .. 3:
    let r = mk(i)
    procs.add proc(): int = r.v
  doAssert live == 4
  doAssert procs[^1]() == 3

block globalPragmaInProc:
  # a `{.global.}` of a proc is initialized once and keeps its value; a
  # lambda naming it must not make the scope destroy it
  proc counter(): int =
    var total = 0
    for i in 1 .. 3:
      var acc {.global.} = @[10]
      let add = proc() = acc.add i
      add()
      total = acc.len
    result = total
  doAssert counter() == 4
  doAssert counter() == 7
