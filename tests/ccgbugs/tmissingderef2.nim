discard """
  output: "c"
"""

# bug #5079

import tables

type Test = ref object
  s: string

proc `test=`(t: Test, s: string) =
  t.s = s

var t = Test()

#t.test = spaces(2) # -- works

var a = newTable[string, string]()
a["b"] = "c"

#t.s = a["b"] # -- works
#t.test a["b"] # -- works
t.test = a["b"] # -- prints "out of memory" and quits
echo t.s
