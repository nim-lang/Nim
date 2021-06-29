discard """
  nimout: '''
IntLit 5
proc (x: int): string => typeDesc[proc[string, int]]
proc (x: int): void => typeDesc[proc[void, int]]
proc (x: int) => typeDesc[proc[void, int]]
x => seq[int]
a
s
d
f
TTaa
TTaa
TTaa
TTaa
true
true
nil
42
false
true
@[i0, i1, i2, i3, i4]
@[tmp, tmp, tmp, tmp, tmp]
'''

  output: '''
range[0 .. 100]
array[0 .. 100, int]
10
test
0o377'i8
0o000000000755'i32
1
2
3
foo1
foo2
foo3
true
false
true
false
1.0
'''
"""


import macros, parseutils


block t7723:
  macro foo1(): untyped =
    result = newStmtList()
    result.add quote do:
      proc init(foo: int, bar: typedesc[int]): int =
        foo

  #expandMacros:
  foo1()

  doAssert init(1, int) == 1



block t8706:
  macro varargsLen(args:varargs[untyped]): untyped =
    doAssert args.kind == nnkArgList
    doAssert args.len == 0
    result = newLit(args.len)

  template bar(a0:varargs[untyped]): untyped =
    varargsLen(a0)

  template foo(x: int, a0:varargs[untyped]): untyped =
    bar(a0)

  doAssert foo(42) == 0
  doAssert bar() == 0



block t9194:
  type
    Foo1 = range[0 .. 100]
    Foo2 = array[0 .. 100, int]

  macro get(T: typedesc): untyped =
    # Get the X out of typedesc[X]
    let tmp = getTypeImpl(T)
    result = newStrLitNode(getTypeImpl(tmp[1]).repr)

  echo Foo1.get
  echo Foo2.get



block t1944:
  template t(e: untyped): untyped =
    macro m(eNode: untyped): untyped =
      echo eNode.treeRepr
    m e

  t 5


block t926:
  proc test(f: var NimNode) {.compileTime.} =
    f = newNimNode(nnkStmtList)
    f.add newCall(newIdentNode("echo"), newLit(10))

  macro blah(prc: untyped): untyped =
    result = prc
    test(result)

  proc test() {.blah.} =
    echo 5



block t2211:
  macro showType(t:typed): untyped =
    let ty = t.getType
    echo t.repr, " => ", ty.repr

  showType(proc(x:int): string)
  showType(proc(x:int): void)
  showType(proc(x:int))

  var x: seq[int]
  showType(x)



block t1140:
  proc parse_until_symbol(node: NimNode, value: string, index: var int): bool {.compiletime.} =
    var splitValue: string
    var read = value.parseUntil(splitValue, '$', index)

    # when false:
    if false:
        var identifier: string
        read = value.parseWhile(identifier, {}, index)
        node.add newCall("add", ident("result"), newCall("$", ident(identifier)))

    if splitValue.len > 0:
        node.insert node.len, newCall("add", ident("result"), newStrLitNode(splitValue))

  proc parse_template(node: NimNode, value: string) {.compiletime.} =
      var index = 0
      while index < value.len and
          parse_until_symbol(node, value, index): discard

  macro tmpli(body: untyped): typed =
      result = newStmtList()
      result.add parseExpr("result = \"\"")
      result.parse_template body[1].strVal


  proc actual: string {.used.} = tmpli html"""
      <p>Test!</p>
      """

  proc another: string {.used.} = tmpli html"""
      <p>what</p>
      """



block tbugs:
  type
    Foo = object
      s: char

  iterator test2(f: string): Foo =
    for i in f:
      yield Foo(s: i)

  macro test(): untyped =
    for i in test2("asdf"):
      echo i.s

  test()


  # bug 1297

  type TType = tuple[s: string]

  macro echotest(): untyped =
    var t: TType
    t.s = ""
    t.s.add("test")
    result = newCall(newIdentNode("echo"), newStrLitNode(t.s))

  echotest()

  # bug #1103

  type
      Td = tuple
          a:string
          b:int

  proc get_data(d: Td) : string {.compileTime.} =
      result = d.a # Works if a literal string is used here.
      # Bugs if line A or B is active. Works with C
      result &= "aa"          # A
      #result.add("aa")       # B
      #result = result & "aa" # C

  macro m(s:static[Td]) : untyped =
      echo get_data(s)
      echo get_data(s)
      result = newEmptyNode()

  const s = ("TT", 3)
  m(s)
  m(s)

  # bug #933

  proc nilcheck(): NimNode {.compileTime.} =
    echo(result == nil) # true
    echo(result.isNil) # true
    echo(repr(result)) # nil

  macro testnilcheck(): untyped =
    result = newNimNode(nnkStmtList)
    discard nilcheck()

  testnilcheck()

  # bug #1323

  proc calc(): array[1, int] =
    result[0].inc()
    result[0].inc()

  const c = calc()
  doAssert c[0] == 2


  # bug #3046

  macro sampleMacroInt(i: int): untyped =
    echo i.intVal

  macro sampleMacroBool(b: bool): untyped =
    echo b.boolVal

  sampleMacroInt(42)
  sampleMacroBool(false)
  sampleMacroBool(system.true)


# bug #11131
macro toRendererBug(n): untyped =
  result = newLit repr(n)

echo toRendererBug(0o377'i8)
echo toRendererBug(0o755'i32)

# bug #12129
macro foobar() =
  var loopVars = newSeq[NimNode](5)
  for i, sym in loopVars.mpairs():
    sym = ident("i" & $i)
  echo loopVars
  for sym in loopVars.mitems():
    sym = ident("tmp")
  echo loopVars

foobar()


# bug #13253
import macros

type
  FooBar = object
    a: seq[int]

macro genFoobar(a: static FooBar): untyped =
  result = newStmtList()
  for b in a.a:
    result.add(newCall(bindSym"echo", newLit b))

proc foobar(a: static FooBar) =
  genFoobar(a)  # removing this make it work
  for b in a.a:
    echo "foo" & $b

proc main() =
  const a: seq[int] = @[1, 2,3]
  # Error: type mismatch: got <array[0..2, int]> but expected 'seq[int]'
  const fb = Foobar(a: a)
  foobar(fb)
main()

# bug #13484

proc defForward(id, nid: NimNode): NimNode =
  result = newProc(id, @[newIdentNode("bool"), newIdentDefs(nid, newIdentNode("int"))], body=newEmptyNode())

proc defEven(evenid, oddid, nid: NimNode): NimNode =
  result = quote do:
    proc `evenid`(`nid`: int): bool =
      if `nid` == 0:
        return true
      else:
        return `oddid`(`nid` - 1)

proc defOdd(evenid, oddid, nid: NimNode): NimNode =
  result = quote do:
    proc `oddid`(`nid`: int): bool =
      if `nid` == 0:
        return false
      else:
        return `evenid`(`nid` - 1)

proc callNode(funid, param: NimNode): NimNode =
  result = quote do:
    `funid`(`param`)

macro testEvenOdd3(): untyped =
  let
    evenid = newIdentNode("even3")
    oddid = newIdentNode("odd3")
    nid = newIdentNode("n")
    oddForward = defForward(oddid, nid)
    even = defEven(evenid, oddid, nid)
    odd = defOdd(evenid, oddid, nid)
    callEven = callNode(evenid, newLit(42))
    callOdd = callNode(oddid, newLit(42))
  result = quote do:
    `oddForward`
    `even`
    `odd`
    echo `callEven`
    echo `callOdd`

macro testEvenOdd4(): untyped =
  let
    evenid = newIdentNode("even4")
    oddid = newIdentNode("odd4")
    nid = newIdentNode("n")
    oddForward = defForward(oddid, nid)
    even = defEven(evenid, oddid, nid)
    odd = defOdd(evenid, oddid, nid)
    callEven = callNode(evenid, newLit(42))
    callOdd = callNode(oddid, newLit(42))
  # rewrite the body of proc node.
  oddForward[6] = newStmtList()
  result = quote do:
    `oddForward`
    `even`
    `odd`
    echo `callEven`
    echo `callOdd`

macro testEvenOdd5(): untyped =
  let
    evenid = genSym(nskProc, "even5")
    oddid = genSym(nskProc, "odd5")
    nid = newIdentNode("n")
    oddForward = defForward(oddid, nid)
    even = defEven(evenid, oddid, nid)
    odd = defOdd(evenid, oddid, nid)
    callEven = callNode(evenid, newLit(42))
    callOdd = callNode(oddid, newLit(42))
  result = quote do:
    `oddForward`
    `even`
    `odd`
    echo `callEven`
    echo `callOdd`

macro testEvenOdd6(): untyped =
  let
    evenid = genSym(nskProc, "even6")
    oddid = genSym(nskProc, "odd6")
    nid = newIdentNode("n")
    oddForward = defForward(oddid, nid)
    even = defEven(evenid, oddid, nid)
    odd = defOdd(evenid, oddid, nid)
    callEven = callNode(evenid, newLit(42))
    callOdd = callNode(oddid, newLit(42))
  # rewrite the body of proc node.
  oddForward[6] = newStmtList()
  result = quote do:
    `oddForward`
    `even`
    `odd`
    echo `callEven`
    echo `callOdd`

# it works
testEvenOdd3()

# it causes an error (redefinition of odd4), which is correct
assert not compiles testEvenOdd4()

# it caused an error (still forwarded: odd5)
testEvenOdd5()

# it works, because the forward decl and definition share the symbol and the compiler is forgiving here
#testEvenOdd6() #Don't test it though, the compiler may become more strict in the future

# bug #15385
var captured_funcs {.compileTime.}: seq[NimNode] = @[]

macro aad*(fns: varargs[typed]): typed =
  result = newStmtList()
  for fn in fns:
    captured_funcs.add fn[0]
    result.add fn

func exp*(x: float): float ## get different error if you remove forward declaration

func exp*(x: float): float {.aad.} =
  var x1 = min(max(x, -708.4), 709.8)
  var result: float   ## looks weird because it is taken from template expansion
  result = x1 + 1.0
  result

template check_accuracy(f: untyped, rng: Slice[float], n: int, verbose = false): auto =

  proc check_accuracy: tuple[avg_ulp: float, max_ulp: int] {.gensym.} =
    let k = (rng.b - rng.a) / (float) n
    var
      res, x: float
      i, max_ulp = 0
      avg_ulp = 0.0

    x = rng.a
    while (i < n):
      res = f(x)
      i.inc
      x = x + 0.001
    (avg_ulp, max_ulp)
  check_accuracy()

discard check_accuracy(exp, -730.0..709.4, 4)

# And without forward decl
macro aad2*(fns: varargs[typed]): typed =
  result = newStmtList()
  for fn in fns:
    captured_funcs.add fn[0]
    result.add fn

func exp2*(x: float): float {.aad2.} =
  var x1 = min(max(x, -708.4), 709.8)
  var result: float   ## looks weird because it is taken from template expansion
  result = x1 + 1.0
  result

template check_accuracy2(f: untyped, rng: Slice[float], n: int, verbose = false): auto =

  proc check_accuracy2: tuple[avg_ulp: float, max_ulp: int] {.gensym.} =
    let k = (rng.b - rng.a) / (float) n
    var
      res, x: float
      i, max_ulp = 0
      avg_ulp = 0.0

    x = rng.a
    while (i < n):
      res = f(x)
      i.inc
      x = x + 0.001
    (avg_ulp, max_ulp)
  check_accuracy2()

discard check_accuracy2(exp2, -730.0..709.4, 4)

# And minimized:
macro aadMin(fn: typed): typed = fn

func expMin: float

func expMin: float {.aadMin.} = 1

echo expMin()


# doubly-typed forward decls
macro noop(x: typed) = x
noop:
  proc cally() = discard

cally()

noop:
  proc barry()

proc barry() = discard

# some more:
proc barry2() {.noop.}
proc barry2() = discard

proc barry3() {.noop.}
proc barry3() {.noop.} = discard


# issue #15389
block double_sem_for_procs:

  macro aad(fns: varargs[typed]): typed =
    result = newStmtList()
    for fn in fns:
      result.add fn

  func exp(x: float): float {.aad.} =
    var x1 = min(max(x, -708.4), 709.8)
    if x1 > 0.0:
      return x1 + 1.0
    result = 10.0

  discard exp(5.0)
