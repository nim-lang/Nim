discard """
  nimout: "t8821.nim(6, 3) Error: Your case statement contains too many branches, consider using if/else instead!"
"""

proc isInt32(i: int): bool =
  case i 
  of 1 .. 70000:
    return true
  else:
    return false

discard isInt32(1)