discard """
  action: compile
  cmd: "nim c -c --cpu:i386 --os:linux --mm:orc $file"
  nimout: '''
@[2, 3, 4, 5]
[@[1], @[2, 3]]
@[(a: 10, b: 20), (a: 40, b: 50), (a: 70, b: 80)]
'''
"""

# bug #26419: the bulk seq copy used the target's `sizeof(int)` (4 on i386)
# for the VM's 8 byte ints and copied only half of the elements

type O = object
  a: int
  b: int8

static:
  var s = @[8, 9, 10, 11]
  let t = @[2, 3, 4, 5]
  s = t
  echo s

  var x = [@[7], @[8, 9]]
  let y = [@[1], @[2, 3]]
  x = y
  echo x

  var o = @[O(a: 1, b: 2), O(a: 4, b: 5)]
  let p = @[O(a: 10, b: 20), O(a: 40, b: 50), O(a: 70, b: 80)]
  o = p
  echo o
