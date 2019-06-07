
# bug #9505

import std/[
    strutils, ospaths, os
]
import pkg/[
  regex
]

proc fun() =
  let a = [
    1,
    2,
  ]
  discard

proc funB() =
  let a = [
    1,
    2,
    3
  ]
  discard
