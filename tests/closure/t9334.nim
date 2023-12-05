discard """
  cmd: "nim $target --hints:off $options -r $file"
  nimout: '''@[1]
@[1, 1]
'''
  nimoutFull: true
"""
proc p(s: var seq[int]): auto =
  let sptr = addr s
  return proc() = sptr[].add 1

proc f =
  var data = @[1]
  p(data)()
  echo repr data

static:
  f() # prints [1]
f() # prints [1, 1]
