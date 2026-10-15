discard """
  errormsg: "type mismatch"
  line: "11"
"""

# bug #26048: declarations in a `when nimvm` branch must not be visible
# to runtime code, they only exist for VM compilation.
proc w(_: bool): bool = false
when nimvm:
  proc w(_: int): bool = true
doAssert not w(0)
