discard """
  targets: "c cpp js"
"""

import std/os
from std/sequtils import toSeq

iterator items(a: array[3, string]): lent string {.inline.} =
  for i in 0..2:
    yield a[i]

static:
  const key = "NIM_TESTS_TOSENV_KEY"
  for val in items(["a", "b", "c"]):
    putEnv(key, val)
    doAssert (key, val) in toSeq(envPairs())
