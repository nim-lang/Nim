proc callFoo*[T](x: T): int =
  mixin foo
  foo(x)
