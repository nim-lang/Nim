discard """
  output: 10.0
"""

type
  MyFloat = object
    val: float

converter to_myfloat*(x: float): MyFloat {.inline.} =
  MyFloat(val: x)

proc `+`(x1, x2: MyFloat): MyFloat =
  MyFloat(val: x1.val + x2.val)

proc `*`(x1, x2: MyFloat): MyFloat =
    MyFloat(val: x1.val * x2.val)

template optMul{`*`(a, 2.0)}(a: MyFloat): MyFloat =
  a + a

func floatMyFloat(x: MyFloat): MyFloat =
  result = x * 2.0

func floatDouble(x: float): float =
  result = x * 2.0

echo floatDouble(5)