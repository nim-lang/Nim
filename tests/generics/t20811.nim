discard """
  output: '''42
42'''
"""

proc outer(j: int) =
  proc genericInner[T](): int =
    j

  proc plainInner(): int =
    j

  echo genericInner[int]()
  echo plainInner()

outer(42)