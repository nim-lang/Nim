from strutils import endsWith, split
from os import isAbsolute

from macros import quote, newIdentNode
include "system/helpers.nim" # for $instantiationInfo

proc checkMsg*(msg, expectedEnd, name: string)=
  let filePrefix = msg.split(' ', maxSplit = 1)[0]
  if not filePrefix.isAbsolute:
    echo name, ":not absolute: `", msg & "`"
  elif not msg.endsWith expectedEnd:
    echo name, ":expected suffix:\n`" & expectedEnd & "`\ngot:\n`" & msg & "`"
  else:
    echo name, ":ok"

macro assertEquals*(lhs, rhs): untyped =
  # We can't yet depend on `unittests` in testament, so we define this
  # simple macro that shows helpful error on failure.
  result = quote do:
    let lhs2 = `lhs`
    let rhs2 = `rhs`
    if lhs2 != rhs2:
      const loc = instantiationInfo(-1, true)
      var msg = "`assertEquals` failed at " & $loc
      # brackets are needed to spot differences with invisible chars (eg space).
      msg.add "\nlhs:{" & $lhs2 & "}\nrhs:{" & $rhs2 & "}"
      doAssert false, msg
