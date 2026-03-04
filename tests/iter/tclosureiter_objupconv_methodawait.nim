discard """
  cmd: "nim c $file"
"""

import std/asyncdispatch

type
  A {.inheritable.} = ref object
  B = ref object of A

method a(x: A): Future[A] {.async, base.} =
  B(await a(B()))
