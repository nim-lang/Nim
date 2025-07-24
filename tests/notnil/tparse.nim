# issue #16324

{.push experimental: "notnil".}

block:
  type Foo = ref object
    value: int
    
  proc newFoo1(): Foo not nil =               # This compiles
    return Foo(value: 1)
    
  proc newFoo2(): Foo not nil {.inline.} =    # This does not
    return Foo(value: 1)

  doAssert newFoo1().value == 1
  doAssert newFoo2().value == 1

{.pop.}
