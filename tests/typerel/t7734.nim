type
  Foo[T: SomeFloat] = object
    learning_rate: T

  Bar[T: SomeFloat] = object
    learning_rate: T
    momentum: T

  Model = object
    weight: int

  FooClass = Foo or Bar


proc optimizer[M; T: SomeFloat](model: M, _: typedesc[Foo], learning_rate: T): Foo[T] =
  result.learning_rate = learning_rate

let a = Model(weight: 1)
let opt = a.optimizer(Foo, 10.0)
