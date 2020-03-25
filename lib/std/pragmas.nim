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

template evalonce*(lhs, typ, expr) =
  ## makes sure `expr` is evaluated once, and no copy is done when using
  ## lvalues. The only current limitation is when expr is an expression returning
  ## an openArray and is not a symbol.
  runnableExamples:
    let s = @[1,2]
    let s2 {.evalonce.} = s
    doAssert s2[0].unsafeAddr == s[0].unsafeAddr
  when type(expr) is openArray:
    static: doAssert typ is type(nil) # we could support but a bit pointless
    # caveat: that's the only case that's not sideeffect safe;
    # it could be made safe either with 1st class openArray, or with a
    # macro that transforms `expr` aka `(body; last)` into:
    # `body; let tmp = unsafeAddr(last)`
    template lhs: untyped = expr
  elif compiles(unsafeAddr(expr)): # `unsafeAddr` is needed here!
    when typ is type(nil):
      let tmp = unsafeAddr(expr)
    else:
      let tmp: ptr typ = unsafeAddr(expr)
    template lhs: untyped = tmp[]
  else:
    when typ is type(nil):
      let lhs = expr
    else:
      let lhs: typ = expr
