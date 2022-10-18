discard """
output: '''
i2416
33
foo55
foo8.0
fooaha
bar7
10
4true
132
20
1
-1
4
11
26
57
-1-1-1
  4
4
  4
  11
11
  4
  11
  26
26
  4
  11
  26
  57
57
-1-1-1
'''
"""

import macros




import i2416
i2416()


import mcan_access_hidden_field
var myfoo = createFoo(33, 44)
echo myfoo.geta


import mgensym_generic_cross_module
foo(55)
foo 8.0
foo "aha"
bar 7



block generic_templates:
  type
    SomeObj = object of RootObj
    Foo[T, U] = object
      x: T
      y: U

  template someTemplate[T](): tuple[id: int32, obj: T] =
    var result: tuple[id: int32, obj: T] = (0'i32, T())
    result

  let ret = someTemplate[SomeObj]()

  # https://github.com/nim-lang/Nim/issues/7829
  proc inner[T](): int =
    discard

  template outer[A](): untyped =
    inner[A]()

  template outer[B](x: int): untyped =
    inner[B]()

  var i1 = outer[int]()
  var i2 = outer[int](i1)

  # https://github.com/nim-lang/Nim/issues/7883
  template t1[T: int|int64](s: string): T =
     var t: T
     t

  template t1[T: int|int64](x: int, s: string): T =
     var t: T
     t

  var i3: int = t1[int]("xx")

from strutils import contains

block tgetast_typeliar:
  proc error(s: string) = quit s

  macro assertOrReturn2(condition: bool; message: string) =
    var line = condition.lineInfo()
    result = quote do:
      block:
        if not likely(`condition`):
          error("Assertion failed: " & $(`message`) & "\n" & `line`)
          return

  macro assertOrReturn(condition: bool) =
    var message : NimNode = newLit(condition.repr)
    # echo message
    result = getAst assertOrReturn2(condition, message)
    # echo result.repr
    let s = result.repr
    doAssert """error("Assertion failed:""" in s

  proc point(size: int16): tuple[x, y: int16] =
    # returns random point in square area with given `size`
    assertOrReturn size > 0



type
  MyFloat = object
    val: float
converter to_myfloat(x: float): MyFloat {.inline.} =
  MyFloat(val: x)

block pattern_with_converter:
  proc `+`(x1, x2: MyFloat): MyFloat =
    MyFloat(val: x1.val + x2.val)

  proc `*`(x1, x2: MyFloat): MyFloat =
      MyFloat(val: x1.val * x2.val)

  template optMul{`*`(a, 2.0)}(a: MyFloat): MyFloat =
    a + a

  func floatMyFloat(x: MyFloat): MyFloat =
    result = x * 2.0

  func floatDouble(x: float): float =
    result = x * 2.0

  doAssert floatDouble(5) == 10.0




block procparshadow:
  template something(name: untyped) =
    proc name(x: int) =
      var x = x # this one should not be rejected by the compiler (#5225)
      echo x

  something(what)
  what(10)

  # bug #4750
  type
    O = object
      i: int
    OP = ptr O

  template alf(p: pointer): untyped =
    cast[OP](p)

  proc t1(al: pointer) =
    var o = alf(al)

  proc t2(alf: pointer) =
    var x = alf
    var o = alf(x)



block symchoicefield:
  type Foo = object
    len: int

  var f = Foo(len: 40)

  template getLen(f: Foo): int = f.len

  doAssert f.getLen == 40
  # This fails, because `len` gets the nkOpenSymChoice
  # treatment inside the template early pass and then
  # it can't be recognized as a field anymore



import os, times
include "sunset.nimf"
block ttempl:
  const
    tabs = [["home", "index"],
            ["news", "news"],
            ["documentation", "documentation"],
            ["download", "download"],
            ["FAQ", "question"],
            ["links", "links"]]


  var i = 0
  for item in items(tabs):
    var content = $i
    var file: File
    if open(file, changeFileExt(item[1], "html"), fmWrite):
      write(file, sunsetTemplate(current=item[1], ticker="", content=content,
                                  tabs=tabs))
      close(file)
    else:
      write(stdout, "cannot open file for writing")
    inc(i)



block ttempl4:
  template `:=`(name, val: untyped) =
    var name = val

  ha := 1 * 4
  hu := "ta-da" == "ta-da"
  echo ha, hu




import mtempl5
block ttempl5:
  echo templ()

  #bug #892
  proc parse_to_close(value: string, index: int, open='(', close=')'): int =
      discard

  # Call parse_to_close
  template get_next_ident =
      discard "{something}".parse_to_close(0, open = '{', close = '}')

  get_next_ident()

  #identifier expected, but found '(open|open|open)'
  #bug #880 (also example in the manual!)
  template typedef(name: untyped, typ: typedesc) =
    type
      `T name` {.inject.} = typ
      `P name` {.inject.} = ref `T name`

  typedef(myint, int)
  var x: PMyInt



block templreturntype:
  template `=~` (a: int, b: int): bool = false
  var foo = 2 =~ 3

# bug #7117
template parse9(body: untyped): untyped =

  template val9(arg: string): int {.inject.} =
    var b: bool
    if b: 10
    else: 20

  body

parse9:
  echo val9("1")


block gensym1:
  template x: untyped = -1
  template t1() =
    template x: untyped {.gensym.} = 1
    echo x()  # 1
  template t2() =
    template x: untyped = 1  # defaults to {.inject.}
    echo x()  # -1  injected x not available during template definition
  t1()
  t2()

block gensym2:
  let x,y,z = -1
  template `!`(xx,yy: typed): untyped =
    template x: untyped {.gensym.} = xx
    template y: untyped {.gensym.} = yy
    let z = x + x + y
    z
  var
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
  echo a ! b
  echo a ! b ! c
  echo a ! b ! c ! d
  echo a ! b ! c ! d ! e
  echo x,y,z

block gensym3:
  macro liftStmts(body: untyped): auto =
    # convert
    #   template x: untyped {.gensym.} =
    #     let z = a + a + b
    #     echo z
    #     z
    # to
    #   let z = a + a + b
    #   echo z
    #   template x: untyped {.gensym.} =
    #     z
    #echo body.repr
    body.expectKind nnkStmtList
    result = newNimNode nnkStmtList
    for s in body:
      s.expectKind nnkTemplateDef
      var sle = s[6]
      while sle.kind == nnkStmtList:
        doAssert(sle.len==1)
        sle = sle[0]
      if sle.kind == nnkStmtListExpr:
        let n = sle.len
        for i in 0..(n-2):
          result.add sle[i]
        var td = newNimNode nnkTemplateDef
        for i in 0..5:
          td.add s[i]
        td.add sle[n-1]
        result.add td
      else:
        result.add s
    #echo result.repr
  let x,y,z = -1
  template `!`(xx,yy: typed): untyped =
    liftStmts:
      template x: untyped {.gensym.} = xx
      template y: untyped {.gensym.} = yy
    let z = x + x + y
    echo "  ", z
    z
  var
    a = 1
    b = 2
    c = 3
    d = 4
    e = 5
  echo a ! b
  echo a ! b ! c
  echo a ! b ! c ! d
  echo a ! b ! c ! d ! e
  echo x,y,z


block identifier_construction_with_overridden_symbol:
  # could use add, but wanna make sure it's an override no matter what
  func examplefn = discard
  func examplefn(x: int) = discard

  # the function our template wants to use
  func examplefn1 = discard

  template exampletempl(n) =
    # attempt to build a name using the overridden symbol "examplefn"
    `examplefn n`()

  exampletempl(1)
