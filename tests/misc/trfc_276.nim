# https://github.com/nim-lang/RFCs/issues/276

proc test1 =
  const a = block:
    let i = 2
    i
  doAssert a == 2
test1()

static: # bug #10938
  for i in '1' .. '2':
    var s: set[char]
    doAssert s == {}
    incl(s, i)

block:
  # this was causing issues in some variants
  const SymChars: set[char] = {'a' .. 'b'}
  var a = 'x'
  discard contains(SymChars, a)

static:
  let i = 1
  var i2 = 2
  doAssert (i, i2) == (1, 2)

proc test2() =
  static:
    let i = 1
    var i2 = 2
    doAssert (i, i2) == (1, 2)
test2()

block:
  type Foo = ref object
  const
    a: Foo = nil

block:
  type Fn = proc (a: cint) {.noconv.} # see CSighandlerT
  const
    foo = cast[Fn](0)

block: # bug #13918
  const test = block:
    var s = ""
    for i in 1 .. 5:
      var arr: array[3, int]
      var val: int
      s.add $arr & " " & $val
      for j in 0 ..< len(arr):
        arr[j] = i
        val = i
    s
  doAssert test == "[0, 0, 0] 0[0, 0, 0] 0[0, 0, 0] 0[0, 0, 0] 0[0, 0, 0] 0"

block: # bug #13312
  static:
    for _ in 0 ..< 3:
      var s: string
      s.add("foo")
      assert s == "foo"

block: # bug #13887
  static: # https://github.com/nim-lang/Nim/issues/13887#issuecomment-655829572
    var x = 5
    var y = addr(x)
    y[] += 10
    doAssert x == y[]

  block: # Example 1
    template fun() =
      var s = @[10,11,12]
      let z = s[0].addr
      doAssert z[] == 10
      z[] = 100
      doAssert z[] == 100
      doAssert s[0] == 100 # was failing here
    static: fun() # was failing here
    fun() # was working

  block: # Example 2
    template fun() =
      var s = @[10,11,12]
      let a1 = cast[int](s[0].addr) # 4323682360
      let z = s[0].addr 
      let a2 = cast[int](z) # 10 => BUG
      doAssert a1 == a2
    static: fun() # fails

  block: # Example 3
    template fun() =
      var s = @[10.1,11.2,12.3]
      let a1 = cast[int](s[0].addr)
      let z = s[0].addr
      let a2 = cast[int](z)
    static: fun()

block: # bug #12172
  const a = block:
    var test: array[5, string]
    test
  proc test =
    const a2 = block:
      var test: array[5, string] # was error here
      test
  proc test2 =
    const a3 = block:
      let i = 0 # Error here too
      i

when false:
  # xxx this doesn't work yet
  block:
    proc test =
      const a = block:
        template fn(x): untyped =
          let i = 0
          i
        fn(123)
