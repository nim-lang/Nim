from os import parentDir, `/`

type
  Vector2 {.importc: "Vector2", header: currentSourcePath().parentDir()/"rect.h".} = object
    x: cfloat
    y: cfloat
var v1 = Vector2(x: 56, y: 78)
var v2: Vector2

v2.deepCopy(v1)

doAssert v1 == v1
doAssert v2 == Vector2(x: 56, y: 78)
