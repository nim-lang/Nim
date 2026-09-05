# issue #26044

discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: reject
  nimout: '''
t26044.nim(15, 11) Error: undeclared identifier: 'g'
t26044.nim(15, 11) Error: expression 'g' has no type (or is ambiguous)
'''
"""

proc p =
  when nimvm:
    var g: int
  discard g
p()
