discard """
  matrix: "--mm:refc; --mm:arc"
"""

block: # bug #23354
  block:
    type AnObject = object of RootObj
      value: int

    proc mutate(a: sink AnObject) =
      a.value = 1

    var obj = AnObject(value: 42)
    mutate(obj)
    doAssert obj.value == 42

  block:
    type AnObject = object of RootObj
      value: int

    proc mutate(a: sink AnObject) =
      a.value = 1

    proc foo =
      var obj = AnObject(value: 42)
      mutate(obj)
      doAssert obj.value == 42

    foo()

block: # bug #12340
  block:
    func consume(x: sink seq[int]) =
      x[0] += 5

    let x = @[1, 2, 3, 4]
    consume x
    doAssert x == @[1, 2, 3, 4]

  # TODO: fixme: complete https://github.com/nim-lang/Nim/pull/23359 for refc
  when false:
    func consume(x: sink seq[int]) =
      x[0] += 5

    proc foo =
      let x = @[1, 2, 3, 4]
      consume x
      doAssert x == @[1, 2, 3, 4]

    foo()
