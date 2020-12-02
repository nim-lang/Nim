import macros

macro m(u:untyped):untyped =
  doAssert hasArgOfName(params u,"s")
  doAssert hasArgOfName(params u,"i")
  doAssert hasArgOfName(params u,"j")
  doAssert hasArgOfName(params u,"k")
  doAssert hasArgOfName(params u,"b")
  doAssert hasArgOfName(params u,"xs")
  doAssert hasArgOfName(params u,"ys")
  doAssert not hasArgOfName(params u,"nonexistent")

proc p(s:string; i,j,k:int; b:bool; xs,ys:seq[int] = @[]) {.m.} = discard
