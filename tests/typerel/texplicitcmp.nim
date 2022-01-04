discard """
  output: '''[1 2 3 ]
[1 2 3 ]
[1 2 3 ]'''
"""

# bug #297

import json, tables, algorithm

proc outp(a: openArray[int]) =
  stdout.write "["
  for i in a: stdout.write($i & " ")
  stdout.write "]\n"

proc works() =
  var f = @[3, 2, 1]
  sort(f, system.cmp[int])
  outp(f)

proc weird(json_params: Table) =
  var f = @[3, 2, 1]
  # The following line doesn't compile: type mismatch. Why?
  sort(f, system.cmp[int])
  outp(f)

var t = @[3, 2, 1]
sort(t, system.cmp[int])
outp(t)
works()
weird(initTable[string, JsonNode]())
