discard """
  targets: "c cpp js"
  matrix: ";--gc:arc"
"""

# if excessive, could remove 'cpp' from targets

from strutils import endsWith, contains

template main() =
  doAssert repr({3,5}) == "{3, 5}"

  block:
    type TEnum = enum a, b
    var val = {a, b}
    when nimvm:
      discard
      #[
      # BUG:
      {0, 1}
      {97..99, 65..67}
      ]#
    else:
      doAssert repr(val) == "{a, b}"
      doAssert repr({'a'..'c', 'A'..'C'}) == "{'A', 'B', 'C', 'a', 'b', 'c'}"

    type
      TObj {.pure, inheritable.} = object
        data: int
      TFoo = ref object of TObj
        d2: float
    var foo: TFoo
    new(foo)

  #[
  BUG:
  --gc:arc returns `"abc"`
  regular gc returns with address, e.g. 0x1068aae60"abc", but only 
  for c,cpp backends (not js, vm)
  ]#
  block:
    doAssert repr("abc").endsWith "\"abc\""
    var b: cstring = "def"
    doAssert repr(b).endsWith "\"def\""

  block:
    var c = @[1,2]
    when nimvm:
      discard # BUG: this shows [1, 2] instead of @[1, 2]
    else:
      # BUG (already mentioned above): some backends / gc show address, others don't
      doAssert repr(c).endsWith "@[1, 2]"

    let d = @["foo", "bar"]
    let s = repr(d)
    # depending on backend/gc, we get 0x106a1c350@[0x106a1c390"foo", 0x106a1c3c0"bar"]
    doAssert "\"foo\"," in s

  var arr = [1, 2, 3]
  doAssert repr(arr) == "[1, 2, 3]"

  block: # bug #7878
    proc reprOpenarray(variable: var openarray[int]): string = repr(variable)
    when defined(js): discard # BUG: doesn't work
    else:
      doAssert reprOpenarray(arr) == "[1, 2, 3]"

static: main()
main()
