type
  Bar[T] = Foo[T, T]
  Baz[T] = proc (x: Foo[T, T])
  
  GenericAlias[T] = Foo[T, T]
  GenericAlias2[T] = Foo[Baz[T], T]
  
  Concrete1 = Foo[int, float]
  Concrete2 = proc(x: proc(a: Foo[int, float]))
  
  Foo[T, U] = object
    x: T
    y: U

var
  x1: Bar[float]
  x2: Baz[int]
  x3: Concrete1
  x4: Concrete2
  x5: GenericAlias[int]
  x6: GenericAlias2[string]

