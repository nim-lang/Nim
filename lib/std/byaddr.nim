# see `semLowerLetVarCustomPragma` for compiler support that enables these
# lowerings

template byaddr*(lhs, typ, expr) =
  ## Allows a syntax for lvalue reference, exact analog to
  ## `auto& a = expr;` in C++
  runnableExamples:
    var s = @[10,11,12]
    var a {.byaddr.} = s[0]
    a+=100
    doAssert s == @[110,11,12]
    doAssert a is int
    var b {.byaddr.}: int = s[0]
    doAssert a.addr == b.addr
  when typ is type(nil):
    let tmp = addr(expr)
  else:
    let tmp: ptr typ = addr(expr)
  template lhs: untyped = tmp[]
