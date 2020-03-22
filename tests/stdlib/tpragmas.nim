import std/pragmas

block:
  var s = @[10,11,12]
  var a {.byaddr.} = s[0]
  a+=100
  doAssert s == @[110,11,12]
  doAssert a is int
  var b {.byaddr.}: int = s[0]
  doAssert a.addr == b.addr

  doAssert not compiles(block:
    # redeclaration not allowed
    var foo = 0
    var foo {.byaddr.} = s[0])

  doAssert not compiles(block:
    # ditto
    var foo {.byaddr.} = s[0]
    var foo {.byaddr.} = s[0])

  block:
    var b {.byaddr.} = s[1] # redeclaration ok in sub scope
    b = 123

  doAssert s == @[110,123,12]

  b = b * 10
  doAssert s == @[1100,123,12]

  doAssert not compiles(block:
    var b2 {.byaddr.}: float = s[2])

  doAssert compiles(block:
    var b2 {.byaddr.}: int = s[2])

## We can define custom pragmas in user code
template byUnsafeAddr(lhs, typ, expr) =
  when typ is type(nil):
    let tmp = unsafeAddr(expr)
  else:
    let tmp: ptr typ = unsafeAddr(expr)
  template lhs: untyped = tmp[]

block:
  let s = @["foo", "bar"]
  let a {.byUnsafeAddr.} = s[0]
  doAssert a == "foo"
  doAssert a[0].unsafeAddr == s[0][0].unsafeAddr

block: # nkAccQuoted
  # shows using a keyword, which requires nkAccQuoted
  template `cast`(lhs, typ, expr) =
    when typ is type(nil):
      let tmp = unsafeAddr(expr)
    else:
      let tmp: ptr typ = unsafeAddr(expr)
    template lhs: untyped = tmp[]

  block:
    let s = @["foo", "bar"]
    let a {.`byUnsafeAddr`.} = s[0]
    doAssert a == "foo"
    doAssert a[0].unsafeAddr == s[0][0].unsafeAddr

  block:
    let s = @["foo", "bar"]
    let a {.`cast`.} = s[0]
    doAssert a == "foo"
    doAssert a[0].unsafeAddr == s[0][0].unsafeAddr
