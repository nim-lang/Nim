discard """
  matrix: "--gc:refc; --gc:orc"
"""

block:
  iterator mvalues(t: var seq[seq[int]]): var seq[int] =
    yield t[0]

  var t: seq[seq[int]]

  while false:
    for v in t.mvalues:
      discard

  proc ok =
    while false:
      for v in t.mvalues:
        discard

  ok()

block:
  iterator mvalues(t: var seq[seq[int]]): lent seq[int] =
    yield t[0]

  var t: seq[seq[int]]

  while false:
    for v in t.mvalues:
      discard

  proc ok =
    while false:
      for v in t.mvalues:
        discard

  ok()

