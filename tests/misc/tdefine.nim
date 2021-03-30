discard """
joinable: false
cmd: "nim c -d:booldef -d:booldef2=false -d:intdef=2 -d:strdef=foobar -r $file"
"""

const booldef {.booldefine.} = false
const booldef2 {.booldefine.} = true
const intdef {.intdefine.} = 0
const strdef {.strdefine.} = ""

doAssert defined(booldef)
doAssert defined(booldef2)
doAssert defined(intdef)
doAssert defined(strdef)
doAssert booldef
doAssert not booldef2
doAssert intdef == 2
doAssert strdef == "foobar"

# Intentionally not defined from command line
const booldef3 {.booldefine.} = true
const intdef2 {.intdefine.} = 1
const strdef2 {.strdefine.} = "abc"
type T = object
    when booldef3:
        field1: int
    when intdef2 == 1:
        field2: int
    when strdef2 == "abc":
        field3: int