# issue #6981

{.experimental: "callOperator".}

block: # issue #6981
  proc `()`(a:string, b:string):string = a & b

  var s = newSeq[int](3)

  doAssert s == @[0, 0, 0]

block: # generalized example from #6981
  proc mewSeq[T](a: int)=discard
  proc mewSeq[T]()= discard
  mewSeq[int]()

block: # issue #9831
  type Foo = object
  proc `()`(foo: Foo) = discard
  let x = newSeq[int]()
