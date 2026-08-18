discard """
  matrix: "--mm:refc; --mm:orc"
  output: "ok"
"""

# the loop temp lifted into the env must be deep-copied: a shallow assign from the static const array made refc incRef string literals in static memory

import std/asyncdispatch

const ips = ["::1", "2001:db8::", "::"]

proc overLiteral(): Future[int] {.async.} =
  var n = 0
  for ip in ["::1", "2001:db8::", "::"]:
    await sleepAsync(1)
    n += ip.len
  return n

proc overConst(): Future[int] {.async.} =
  var n = 0
  for ip in ips:
    await sleepAsync(1)
    n += ip.len
  return n

doAssert waitFor(overLiteral()) == 15
doAssert waitFor(overConst()) == 15
echo "ok"
