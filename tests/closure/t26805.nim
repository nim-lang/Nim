discard """
  matrix: "--mm:refc; --mm:orc"
  output: '''
a
a
bx
cx
mid bx
mid cx
outer bx
outer cx
'''
"""

# bug #26805: an iterator capturing an outer routine's variable, used in a
# for loop inside another nested routine

proc outer(args: seq[string]) =
  iterator getAll(): string =
    for arg in args:
      yield arg

  proc getFirst() =
    for value in getAll():
      echo value
      return

  for value in getAll():
    discard

  getFirst()

outer(@["a"])

proc outerB(args: seq[string]) =
  iterator getAll(): string =
    for arg in args:
      yield arg

  proc getFirst() =
    for value in getAll():
      echo value
      return

  getFirst()

outerB(@["a"])

proc outerC(args: seq[string]) =
  var extra = "x"
  iterator getAll(): string =
    for arg in args:
      yield arg & extra

  proc mid() =
    proc deep() =
      for value in getAll():
        echo value
    deep()
    for v in getAll(): echo "mid ", v

  mid()
  for v in getAll(): echo "outer ", v

outerC(@["b", "c"])
