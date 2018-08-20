discard """
  output: "10"
"""

{.experimental: "typeImports".}

from collections.deques import Deque

var dq = initDeque[int]()
dq.addLast(10)
assert len(dq) == 1
echo peekLast(dq)
