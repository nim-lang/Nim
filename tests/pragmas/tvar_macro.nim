import macros

block: # test usage
  macro modify(sec) =
    result = copy sec
    result[0][0] = ident(repr(result[0][0]) & "Modified")

  block:
    let foo {.modify.} = 3
    doAssert fooModified == 3

  block: # in section 
    let
      a = 1
      b {.modify.} = 2
      c = 3
    doAssert (a, bModified, c) == (1, 2, 3)

block: # with single argument
  macro appendToName(name: static string, sec) =
    result = sec
    result[0][0] = ident(repr(result[0][0]) & name)

  block:
    let foo {.appendToName: "Bar".} = 3
    doAssert fooBar == 3

  block:
    let
      a = 1
      b {.appendToName("").} = 2
      c = 3
    doAssert (a, b, c) == (1, 2, 3)

macro appendToNameAndAdd(name: static string, incr: static int, sec) =
  result = sec
  result[0][0] = ident(repr(result[0][0]) & name)
  result[0][2] = infix(result[0][2], "+", newLit(incr))

block: # with multiple arguments
  block:
    let foo {.appendToNameAndAdd("Bar", 5).} = 3
    doAssert fooBar == 8

  block:
    let
      a = 1
      b {.appendToNameAndAdd("", 15).} = 2
      c = 3
    doAssert (a, b, c) == (1, 17, 3)

block: # in other kinds of sections
  block:
    const
      a = 1
      b {.appendToNameAndAdd("", 15).} = 2
      c = 3
    doAssert (a, b, c) == (1, 17, 3)
    doAssert static(b) == b

  block:
    var
      a = 1
      b {.appendToNameAndAdd("", 15).} = 2
      c = 3
    doAssert (a, b, c) == (1, 17, 3)
    b += a
    c += b
    doAssert (a, b, c) == (1, 18, 21)

block: # with other pragmas
  macro appendToNameAndAdd(name: static string, incr, sec) =
    result = sec
    result[0][0][0] = ident(repr(result[0][0][0]) & name)
    result[0][0][1].add(ident"deprecated")
    result[0][2] = infix(result[0][2], "+", incr)

  var
    a = 1
    foo {.exportc: "exportedFooBar", appendToNameAndAdd("Bar", {'0'..'9'}), used.} = {'a'..'z', 'A'..'Z'}
    b = 2
  
  doAssert (a, b) == (1, 2)

  let importedFooBar {.importc: "exportedFooBar", nodecl.}: set[char]

  doAssert importedFooBar == fooBar #[tt.Warning
                             ^ fooBar is deprecated
  ]#
  

block: # with stropping
  macro `cast`(def) =
    let def = def[0]
    let
      lhs = def[0]
      typ = def[1]
      ex = def[2]
      addrTyp = if typ.kind == nnkEmpty: typ else: newTree(nnkPtrTy, typ)
    result = quote do:
      let tmp: `addrTyp` = unsafeAddr(`ex`)
      template `lhs`: untyped = tmp[]
  
  macro assign(def) =
    result = getAst(`cast`(def))

  block:
    let s = @["foo", "bar"]
    let a {.`assign`.} = s[0]
    doAssert a == "foo"
    doAssert a[0].addr == s[0][0].addr

  block:
    let
      s = @["foo", "bar"]
      a {.`cast`.} = s[0]
    doAssert a == "foo"
    doAssert a[0].addr == s[0][0].addr

block: # bug #15920
  macro foo(def) =
    result = def
  proc fun1()=
    let a {.foo.} = 1
  template fun2()=
    let a {.foo.} = 1
  fun1() # ok
  fun2() # BUG
