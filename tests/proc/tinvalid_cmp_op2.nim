discard """
  cmd: "nim check $file"
  action: reject
  nimout: '''
tinvalid_cmp_op2.nim(12, 1) Error: define `<` instead of `>` to implement user defined comparison operator.it allows you to use `>` automatically.
'''
"""

# issue #25655

type Foo = distinct int
func `>`(a, b: Foo): bool = int(a) > int(b)
