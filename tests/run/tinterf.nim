discard """
  output: '''56 66'''
"""

type
  ITest = tuple[
    setter: proc(v: int) {.closure.},
    getter1: proc(): int {.closure.},
    getter2: proc(): int {.closure.}]

proc getInterf(): ITest =
  var shared, shared2: int
  
  return (setter: proc (x: int) = 
            shared = x
            shared2 = x + 10,
          getter1: proc (): int = result = shared,
          getter2: proc (): int = return shared2)

var i = getInterf()
i.setter(56)

echo i.getter1(), " ", i.getter2()

