discard """
    action: run
"""

type
    R = ref
    V = var
    D = distinct
    P = ptr

var x: ref int
var y: distinct int
var z: ptr int

doAssert x is ref
doAssert y is distinct
doAssert z is ptr