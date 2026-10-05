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

block: # shrinking an `@[...]` seq literal in the VM
  # A `@[a, b, c]` seq value keeps the array-literal type in the VM; shrinking it
  # to length 1 must not be misread as a broadcast default array (was: the whole
  # thing collapsed to `len` copies of the first element).
  proc shrink =
    var s = @[10, 20, 30]
    s.setLen(1)
    doAssert s == @[10]
    var t = @["foo", "bar"]
    t.delete(1)
    doAssert t == @["foo"]
  static: shrink()
  shrink()
