type Foo = object
  index: int

block:
  proc fun[T]() =
    var foo: T
    var n = 10

    var foos: seq[T]
    foos.setLen n

    n.inc
    foos.setLen n

    for i in 0 ..< n:
      let temp = foos[i]
      when T is object:
        doAssert temp.index == 0
      when T is ref object:
        doAssert temp == nil
      doAssert temp == foo

  static:
    fun[Foo]()
    fun[int]()
    fun[float]()
    fun[string]()
    fun[(int, string)]()
    fun[ref Foo]()
    fun[seq[int]]()
