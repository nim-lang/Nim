discard """
  description: "Imported nullary templates retain precedence in generic alias lookup"
  output: "42"
"""

import mselectordefaults

proc useSelector[A, R](s: Selector[A, R]) =
  doAssert s.value == 42
  echo s.value

proc init[T]() =
  useSelector(restoreState)

init[int]()
