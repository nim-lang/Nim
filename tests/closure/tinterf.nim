discard """
  output: '''56 66'''
"""

type
  ITest = tuple[
    setter: proc(v: int) {.closure.},
    getter1: proc(): int {.closure.},
    getter2: proc(): int {.closure.}]

proc getInterf(): ITest =
  var shared1, shared2: int
  
  return (setter: proc (x: int) = 
            shared1 = x
            shared2 = x + 10,
          getter1: proc (): int = result = shared1,
          getter2: proc (): int = return shared2)

var i = getInterf()
i.setter(56)

echo i.getter1(), " ", i.getter2()

