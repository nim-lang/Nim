discard """
cmd: "nim check $file"
errormsg: "'t' has unspecified generic parameters"
nimout: '''
t5167_5.nim(10, 16) Error: expression 'system' has no type (or is ambiguous)
t5167_5.nim(21, 9) Error: 't' has unspecified generic parameters
'''
"""
# issue #11942
discard newSeq[system]()

# issue #5167
template t[B]() =
  echo "foo1"

macro m[T]: untyped = nil

proc bar(x: proc (x: int)) =
  echo "bar"

let x = t
bar t

let y = m
bar m
