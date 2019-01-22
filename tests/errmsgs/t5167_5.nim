discard """
cmd: "nim check $file"
errormsg: "'t' has unspecified generic parameters"
nimout: '''
t5167_5.nim(20, 9) Error: 't' has unspecified generic parameters
'''
"""




template t[B]() =
  echo "foo1"

macro m[T]: untyped = nil

proc bar(x: proc (x: int)) =
  echo "bar"

let x = t
bar t

let y = m
bar m

