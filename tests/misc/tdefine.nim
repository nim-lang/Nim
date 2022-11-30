discard """
joinable: false
cmd: "nim c $options -d:booldef -d:booldef2=false -d:intdef=2 -d:strdef=foobar -d:namespaced.define=false -d:double.namespaced.define -r $file"
matrix: "; -d:useGenericDefine"
"""

when defined(useGenericDefine):
  {.pragma: booldefine2, define.}
  {.pragma: intdefine2, define.}
  {.pragma: strdefine2, define.}
else:
  
  {.pragma: booldefine2, booldefine.}
  {.pragma: intdefine2, intdefine.}
  {.pragma: strdefine2, strdefine.}

const booldef {.booldefine2.} = false
const booldef2 {.booldefine2.} = true
const intdef {.intdefine2.} = 0
const strdef {.strdefine2.} = ""

doAssert defined(booldef)
doAssert defined(booldef2)
doAssert defined(intdef)
doAssert defined(strdef)
doAssert booldef
doAssert not booldef2
doAssert intdef == 2
doAssert strdef == "foobar"

when defined(useGenericDefine):
  block:
    const uintdef {.define: "intdef".}: uint = 17
    doAssert intdef == int(uintdef)
    const cstrdef {.define: "strdef".}: cstring = "not strdef"
    doAssert $cstrdef == strdef
    type FooBar = enum foo, bar, foobar
    const enumdef {.define: "strdef".} = foo
    doAssert $enumdef == strdef
    doAssert enumdef == foobar

# Intentionally not defined from command line
const booldef3 {.booldefine2.} = true
const intdef2 {.intdefine2.} = 1
const strdef2 {.strdefine2.} = "abc"
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
const `namespaced.define` {.booldefine2.} = true
doAssert not `namespaced.define`
when defined(useGenericDefine):
  const aliasToNamespacedDefine {.define: "namespaced.define".} = not `namespaced.define`
else:
  const aliasToNamespacedDefine {.booldefine: "namespaced.define".} = not `namespaced.define`
doAssert aliasToNamespacedDefine == `namespaced.define`

doAssert defined(double.namespaced.define)
const `double.namespaced.define` {.booldefine2.} = false
doAssert `double.namespaced.define`
when defined(useGenericDefine):
  const aliasToDoubleNamespacedDefine {.define: "double.namespaced.define".} = not `double.namespaced.define`
else:
  const aliasToDoubleNamespacedDefine {.booldefine: "double.namespaced.define".} = not `double.namespaced.define`
doAssert aliasToDoubleNamespacedDefine == `double.namespaced.define`

doAssert not defined(namespaced.butnotdefined)
