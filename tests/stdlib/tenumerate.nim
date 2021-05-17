discard """
  targets: "c js"
"""

import std/enumerate

template main() = 
  block: # enumerate
    let a = @[1, 3, 5, 7]
    block:
      var res: seq[(int, int)]
      for i, x in enumerate(a):
        res.add (i, x)
      doAssert res == @[(0, 1), (1, 3), (2, 5), (3, 7)]
    block:
      var res: seq[(int, int)]
      for (i, x) in enumerate(a.items):
        res.add (i, x)
      doAssert res == @[(0, 1), (1, 3), (2, 5), (3, 7)]
    block:
      var res: seq[(int, int)]
      for i, x in enumerate(3, a):
        res.add (i, x)
      doAssert res == @[(3, 1), (4, 3), (5, 5), (6, 7)]

  block: # staticUnroll
    for i, name in staticUnroll([name0, name1]):
      const name = i
    assert name0 == 0
    assert name1 == 1

    # works inside a template too
    template baz =
      for i, name in staticUnroll([name0, name1]):
        const name = i
      assert name1 == 1
    baz()

    block:
      for i, T in staticUnroll([int, float, string]):
        when i == 1:
          var a0 {.inject.}: T
      assert a0 == 0.0

    block:
      proc bar: auto =
        for i, val in staticUnroll([10, 11]):
          return i + val
      assert bar() == 0 + 10

    block:
      var c = 0
      for i in staticUnroll([0, 1]):
        for j in staticUnroll([0, 1]):
          c += i + j
      assert c == 4

static: main()
main()
