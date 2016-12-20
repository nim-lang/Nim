discard """
  output: "vec2"
"""
# bug #5131

import macros

type
    vecBase[I: static[int], T] = distinct array[I, T]
    vec2* = vecBase[2, float32]

proc isRange(n: NimNode, rangeLen: int = -1): bool =
    if n.kind == nnkBracketExpr and $(n[0]) == "range":
        if rangeLen == -1:
            result = true
        elif n[2].intVal - n[1].intVal + 1 == rangeLen:
            result = true

proc getTypeName(t: NimNode, skipVar = false): string =
    case t.kind
    of nnkBracketExpr:
        if $(t[0]) == "array" and t[1].isRange(2) and $(t[2]) == "float32":
            result = "vec2"
        elif $(t[0]) == "array" and t[1].isRange(3) and $(t[2]) == "float32":
            result = "vec3"
        elif $(t[0]) == "array" and t[1].isRange(4) and $(t[2]) == "float32":
            result = "vec4"
        elif $(t[0]) == "distinct":
            result = getTypeName(t[1], skipVar)
    of nnkSym:
        case $t
        of "vecBase": result = getTypeName(getType(t), skipVar)
        of "float32": result = "float"
        else:
            result = $t
    of nnkVarTy:
        result = getTypeName(t[0])
        if not skipVar:
            result = "inout " & result
    else:
        echo "UNKNOWN TYPE: ", treeRepr(t)
        assert(false, "Unknown type")

macro typeName(t: typed): string =
    result = newLit(getTypeName(getType(t)))

var tt : vec2
echo typeName(tt)
