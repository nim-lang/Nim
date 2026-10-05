# Helper: defines a generic whose body uses TScopeSize via the strformat `&`
# macro (late-bound), resolved in THIS module's scope (mtscopea -> 65).
import mtscopea, std/strformat
export mtscopea
func fromRaw*[T](x: T): string =
  const msg = &"size {TScopeSize - 1}"
  result = msg & " " & $int(x)
