discard """
  matrix: "--mm:arc"
"""

type AnObject = object of RootObj
  value*: int

proc mutate(shit: sink AnObject) =
  shit.value = 1

proc foo = # bug #23359
  var bar = AnObject(value: 42)
  mutate(bar)
  doAssert bar.value == 42

foo()
