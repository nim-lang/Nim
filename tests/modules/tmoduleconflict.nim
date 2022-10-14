import module1/defs as md1
import module2/defs as md2

let x = md1.MyObj(field1: 1)
let y = md2.MyObj(field2: 1)
doAssert x.field1 == y.field2
