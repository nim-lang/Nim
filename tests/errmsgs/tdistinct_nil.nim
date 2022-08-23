discard """
  cmd: "nim check $file"
  action: reject
  nimout: '''
tdistinct_nil.nim(23, 4) Error: type mismatch: got <typeof(nil)>
but expected one of:
proc foo(x: DistinctPointer)
  first type mismatch at position: 1
  required type for x: DistinctPointer
  but expression 'nil' is of type: typeof(nil)

expression: foo(nil)
'''
"""

type
  DistinctPointer = distinct pointer

proc foo(x: DistinctPointer) =
  discard

foo(DistinctPointer(nil))
foo(nil)
