
import exposed

type NumberHolder = object
  ival: int
  fval: float

echo "top level statements are executed!"
echo NumberHolder(ival: 10, fval: 2.0)

proc hostProgramRunsThis*(a, b: float): float =
  result = addFloats(a, b, 1.0)

let hostProgramWantsThis* = "my secret"
