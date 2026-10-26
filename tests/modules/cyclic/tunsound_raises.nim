discard """
  errormsg: "isOdd(-2) can raise an unlisted exception: Exception"
  file: "tunsound_raises.nim"
"""

# `isEven` raises and its effects are incomplete while `isOdd` is checked
# from inside it: a recursion via the modules of the group is treated like a
# call of a forward declared routine, so `.raises: []` must not be accepted.
import effects/meven_raises {.cyclic.}

proc isOdd*(n: int): bool = n != 0 and isEven(n - 1)
proc t*() {.raises: [].} = echo isOdd(-2)
t()
