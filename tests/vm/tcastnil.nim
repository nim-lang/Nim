discard """
  nimout: '''nil
nil
nil
nil
nil
nil
'''
"""

block:
  static:
    let a = cast[pointer](nil)
    echo a.repr

block:
  static:
    echo cast[ptr int](nil).repr

block:
  const str = cast[ptr int](nil)
  static:
    echo str.repr

block:
  static:
    echo cast[ptr int](nil).repr

block:
  static:
    echo cast[RootRef](nil).repr

block:
  static:
    echo cast[cstring](nil).repr
