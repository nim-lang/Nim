template byAddrImpl*(n, name, typ, exp): untyped =
  ## Defines a reference syntax for lvalue expressions, analog to C++ `auto& a = expr`.
  ## The expression is evaluated only once, and any side effects will only be
  ## evaluated once, at declaration time.
  ##
  ## Note: to use this, use `byaddr x = expr` (not `byAddrImpl`), see examples.
  runnableExamples:
    var x = @[1,2,3]
    let x0=x[1]
    byaddr x1=x[1]
    x1+=10
    doAssert type(x1) is int and x == @[1,12,3]
  let myAddr = addr `exp`
  template `name`: untyped = myAddr[]
