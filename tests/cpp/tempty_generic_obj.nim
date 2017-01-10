discard """
  cmd: "nim cpp $file"
  output: '''int
float'''
"""

import typetraits

# bug #4625
type
  Vector {.importcpp: "std::vector<'0 >", header: "vector".} [T] = object

proc initVector[T](): Vector[T] {.importcpp: "'0(@)", header: "vector", constructor.}

proc doSomething[T](v: var Vector[T]) =
  echo T.name

var v = initVector[int]()
v.doSomething()

var vf = initVector[float]()
vf.doSomething() # Nim uses doSomething[int] here in C++
