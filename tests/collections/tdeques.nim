discard """
  output: '''true'''
"""

import deques


proc index(self: Deque[int], idx: Natural): int =
  self[idx]

proc main =
  var testDeque = initDeque[int]()
  testDeque.addFirst(1)
  assert testDeque.index(0) == 1

main()
echo "true"
