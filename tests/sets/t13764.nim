discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t13764.nim(15, 9) Error: set is too large; use `std/sets` for ordinal types with more than 2^16 elements



'''
"""

#var a: set[int] # Error: set is too large


let a = {1_000_000} # Compiles
