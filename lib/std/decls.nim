# see `semLowerLetVarCustomPragma` for compiler support that enables these
# lowerings

template byaddr*(lhs, typ, ex) =
  ## Allows a syntax for lvalue reference, exact analog to
  ## `auto& a = ex;` in C++
  runnableExamples:
    var s = @[10,11,12]
    var a {.byaddr.} = s[0]
    a+=100
    doAssert s == @[110,11,12]
    doAssert a is int
    var b {.byaddr.}: int = s[0]
    doAssert a.addr == b.addr
  when typ is typeof(nil):
    let tmp = addr(ex)
  else:
    let tmp: ptr typ = addr(ex)
  template lhs: untyped = tmp[]
