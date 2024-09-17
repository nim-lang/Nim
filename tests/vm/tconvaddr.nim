block: # issue #24097
  type Foo = distinct int
  proc foo(x: var Foo) =
    int(x) += 1
  proc bar(x: var int) =
    x += 1
  static:
    var x = Foo(1)
    int(x) = int(x) + 1
    doAssert x.int == 2
    int(x) += 1
    doAssert x.int == 3
    foo(x)
    doAssert x.int == 4
    bar(int(x)) # need vmgen flags propagated for this
    doAssert x.int == 5
