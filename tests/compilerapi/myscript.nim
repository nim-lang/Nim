
import exposed

echo "top level statements are executed!"

proc hostProgramRunsThis*(a, b: float): float =
  result = addFloats(a, b, 1.0)

let hostProgramWantsThis* = "my secret"
