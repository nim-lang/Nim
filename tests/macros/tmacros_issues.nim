discard """
  msg: '''
proc init(foo129050: int; bar129052: typedesc[int]): int =
  foo129050

IntLit 5
proc (x: int): string => typeDesc[proc[string, int]]
proc (x: int): void => typeDesc[proc[void, int]]
proc (x: int) => typeDesc[proc[void, int]]
x => uncheckedArray[int]
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
'''

  output: '''
range[0 .. 100]
array[0 .. 100, int]
10
test
'''
"""


import macros, parseutils


block t7723:
  macro foo1(): untyped =
    result = newStmtList()
    result.add quote do:
      proc init(foo: int, bar: typedesc[int]): int =
        foo

  expandMacros:
    foo1()

  doAssert init(1, int) == 1



block t8706:
  macro varargsLen(args:varargs[untyped]): untyped =
    doAssert args.kind == nnkArglist
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

  var x: UncheckedArray[int]
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


  proc actual: string = tmpli html"""
      <p>Test!</p>
      """

  proc another: string = tmpli html"""
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
