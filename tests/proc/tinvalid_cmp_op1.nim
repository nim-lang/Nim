discard """
  cmd: "nim check $file"
  action: compile
  nimout: '''
tinvalid_cmp_op1.nim(12, 1) Warning: define `<=` instead of `>=` to implement user defined comparison operator. it allows you to use `>=` automatically. [InvalidCmpOp]
'''
"""

# issue #25655

type Foo = distinct int
func `>=`(a, b: Foo): bool = int(a) >= int(b)
