discard """
  output: '''56'''
"""

type
  ITest = tuple[
    setter: proc(v: int) {.closure.},
    getter: proc(): int {.closure.}]

proc getInterf(): ITest =
  var shared: int
  
  return (setter: proc (x: int) = shared = x,
          getter: proc (): int = return shared)

var i = getInterf()
i.setter(56)

echo i.getter()

