# bug #5540; works in 1.2.0
# fails in 1.0 (Error: cannot generate VM code for)
# fails in 0.18.0 (Error: type mismatch: got <type T>)

block:
  type
    Fruit = object
    Yellow = object
      a: int
  template getColor(x: typedesc[Fruit]): typedesc = Yellow
  type
    Banana[T] = object
      b: T
      a: getColor(Fruit)
    Apple[T] = object
      a: T
      b: getColor(T)
  block:
    var x: Banana[int]
    doAssert x.b == 0
    doAssert x.a is Yellow
  block:
    var x: Apple[Fruit]
    doAssert x.b is Yellow

block:
  type
    Fruit = object
    Yellow = object
      a: int
    
  template getColor(x: typedesc[Fruit]): typedesc = Yellow

  type
    Banana[T] = object
      b: T
      a: getColor(Fruit)

    Apple[T] = object
      a: T
      b: getColor(T)
      
  var x: Banana[int]
  x.b = 13
  x.a.a = 17
