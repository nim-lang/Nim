block:
  proc foo(x: float): string = "float"
  proc foo(x: float32): string = "float32"

  doAssert foo(1.0) == "float"
  doAssert foo(1.0'f32) == "float32"
  # issue #17201
  doAssert foo(1) == "float"
