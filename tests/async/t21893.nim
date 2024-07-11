discard """
output: "@[97]\ntrue"
"""

import asyncdispatch

proc test(): Future[bool] {.async.} =
  const S4 = @[byte('a')]
  echo S4
  return true

echo waitFor test()

