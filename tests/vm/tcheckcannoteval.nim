discard """
  cmd: "nim check $file"
  action: "reject"
  errormsg: "index type 'int' for array is too large"
  nimout: '''
tcheckcannoteval.nim(13, 18) Error: cannot evaluate at compile time: N
'''
"""

# `nim check` used to crash after a `cannot evaluate at compile time` error
# bug #7660
macro foo(N: static[int]): untyped =
  var bar: array[N, int]

