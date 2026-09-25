discard """
  output: "ok"
"""

# The generic invocations in `myNew5`'s return type are loaded Sealed from the
# dependency's NIF. Instantiating them with concrete arguments must not leave
# `tfHasMeta` on the concrete instance, or the call has no type.
import mgenericinstmeta

let x = myNew5(1, "a", 2, "b")
doAssert x != nil
echo "ok"
