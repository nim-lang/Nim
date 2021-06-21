import  macros

macro test*(a: untyped): untyped =
  var nodes: tuple[a, b: int]
  nodes.a = 4
  nodes[1] = 45

  type
    TTypeEx = object
      x, y: int
      case b: bool
      of false: nil
      of true: z: float

  var t: TTypeEx
  t.b = true
  t.z = 4.5


test:
  "hi"


template assertNot(arg: untyped): untyped =
  assert(not(arg))


proc foo(arg: int): void =
  discard

proc foo(arg: float): void =
  discard

static:
  ## test eqIdent
  let a = "abc_def"
  let b = "abcDef"
  let c = "AbcDef"
  let d = nnkBracketExpr.newTree() # not an identifier at all

  assert eqIdent(             a ,              b )
  assert eqIdent(newIdentNode(a),              b )
  assert eqIdent(             a , newIdentNode(b))
  assert eqIdent(newIdentNode(a), newIdentNode(b))

  assert eqIdent(               a ,                b )
  assert eqIdent(genSym(nskLet, a),                b )
  assert eqIdent(               a , genSym(nskLet, b))
  assert eqIdent(genSym(nskLet, a), genSym(nskLet, b))

  assert eqIdent(newIdentNode(  a), newIdentNode(  b))
  assert eqIdent(genSym(nskLet, a), newIdentNode(  b))
  assert eqIdent(newIdentNode(  a), genSym(nskLet, b))
  assert eqIdent(genSym(nskLet, a), genSym(nskLet, b))

  assertNot eqIdent(             c ,              b )
  assertNot eqIdent(newIdentNode(c),              b )
  assertNot eqIdent(             c , newIdentNode(b))
  assertNot eqIdent(newIdentNode(c), newIdentNode(b))

  assertNot eqIdent(               c ,                b )
  assertNot eqIdent(genSym(nskLet, c),                b )
  assertNot eqIdent(               c , genSym(nskLet, b))
  assertNot eqIdent(genSym(nskLet, c), genSym(nskLet, b))

  assertNot eqIdent(newIdentNode(  c), newIdentNode(  b))
  assertNot eqIdent(genSym(nskLet, c), newIdentNode(  b))
  assertNot eqIdent(newIdentNode(  c), genSym(nskLet, b))
  assertNot eqIdent(genSym(nskLet, c), genSym(nskLet, b))

  # eqIdent on non identifier at all
  assertNot eqIdent(a,d)

  # eqIdent on sym choice
  let fooSym = bindSym"foo"
  assert fooSym.kind in {nnkOpenSymChoice, nnkClosedSymChoice}
  assert    fooSym.eqIdent("fOO")
  assertNot fooSym.eqIdent("bar")

  # eqIdent on exported and backtick quoted identifiers
  let procName = ident("proc")
  let quoted = nnkAccQuoted.newTree(procName)
  let exported = nnkPostfix.newTree(ident"*", procName)
  let exportedQuoted = nnkPostfix.newTree(ident"*", quoted)

  let nodes = @[procName, quoted, exported, exportedQuoted]

  for i in 0 ..< nodes.len:
    for j in 0 ..< nodes.len:
      doAssert eqIdent(nodes[i], nodes[j])

  for node in nodes:
    doAssert eqIdent(node, "proc")


  var empty: NimNode
  var myLit = newLit("str")

  assert( (empty or myLit) == myLit )

  empty = newEmptyNode()

  assert( (empty or myLit) == myLit )

  proc bottom(): NimNode =
    quit("may not be evaluated")

  assert( (myLit or bottom()) == myLit )

type
  Fruit = enum
    apple
    banana
    orange

macro foo(x: typed) =
  doAssert Fruit(x.intVal) == banana

foo(banana)
