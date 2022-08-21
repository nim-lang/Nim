discard """
joinable: false
cmd: "nim c -d:booldef -d:booldef2=false -d:intdef=2 -d:strdef=foobar -d:namespaced.define=false -d:double.namespaced.define -r $file"
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

doAssert not defined(booldef3)
doAssert not defined(intdef2)
doAssert not defined(strdef2)
discard T(field1: 1, field2: 2, field3: 3)

doAssert defined(namespaced.define)
const `namespaced.define` {.booldefine.} = true
doAssert not `namespaced.define`

doAssert defined(double.namespaced.define)
const `double.namespaced.define` {.booldefine.} = false
doAssert `double.namespaced.define`

doAssert not defined(namespaced.butnotdefined)
