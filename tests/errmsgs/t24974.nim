discard """
  exitcode: 1
  output: '''
t24974.nim(22)           t24974
t24974.nim(19)           d
t24974.nim(16)           s
assertions.nim(45)       failedAssertImpl
assertions.nim(40)       raiseAssert
fatal.nim(62)            sysFatal
Error: unhandled exception: t24974.nim(16, 26) `false`  [AssertionDefect]
'''
"""


type B = seq[array[1, byte]]
proc s(_: var B): bool = doAssert false
proc d(): B =
  var k: B
  if s(k): discard
  quit 0
  k
for _ in [0]: discard d()
