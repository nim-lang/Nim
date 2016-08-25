
# bug #4600
template foo(x: untyped): untyped = echo 1
template foo(x,y: untyped): untyped = echo 2

proc bar1[T](x: T) = foo(x)
proc bar2(x: float) = foo(x,x)
proc bar3[T](x: T) = foo(x,x)
