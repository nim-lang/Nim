discard """
  exitcode: 0
  output: "hello world"
"""

import asyncdispatch

var foo = newFuture[int]()
foo.addCallback(proc () = echo "hello world")
discard withTimeout(foo, 1)
foo.complete(0)
drain()
