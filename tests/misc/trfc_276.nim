# https://github.com/nim-lang/RFCs/issues/276

proc test1 =
  const a = block:
    let i = 2
    i
  doAssert a == 2
test1()

static:
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

block:
  const test = block:
    var s = ""
    for i in 1 .. 5:
      var arr: array[3, int]
      var val: int
      # echo arr, " ", val
      s.add $arr & " " & $val
      for j in 0 ..< len(arr):
        arr[j] = i
        val = i
    s
  doAssert test == "[0, 0, 0] 0[0, 0, 0] 0[0, 0, 0] 0[0, 0, 0] 0[0, 0, 0] 0"

block:
  static:
    for _ in 0 ..< 3:
      var s: string
      s.add("foo")
      assert s == "foo"

when false:
  # xxx this doesn't work yet
  block:
    proc test =
      const a = block:
        template fn(x): untyped =
          let i = 0
          i
        fn(123)
