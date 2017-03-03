discard """
cmd: "nim check $file"
errormsg: "'m' has unspecified generic parameters"
nimout: '''
t5167_5.nim(20, 9) Error: 't' has unspecified generic parameters
t5167_5.nim(21, 5) Error: 't' has unspecified generic parameters
t5167_5.nim(23, 9) Error: 'm' has unspecified generic parameters
t5167_5.nim(24, 5) Error: 'm' has unspecified generic parameters
'''
"""

template t[B]() =
  echo "foo1"

macro m[T]: stmt = nil

proc bar(x: proc (x: int)) =
  echo "bar"

let x = t
bar t

let y = m
bar m

