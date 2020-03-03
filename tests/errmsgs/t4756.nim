discard """
errormsg: "type mismatch: got <string, arr: seq[empty]>"
line: 15
"""

# https://github.com/nim-lang/Nim/issues/4756

type
  Test* = ref object
    name*: string

proc newTest(name: string, arr: seq): Test =
    result = Test(name: name)

let test = newTest("test", arr = @[])

