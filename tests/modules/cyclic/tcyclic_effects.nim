discard """
  joinable: false
  output: "0 7"
"""

# effect tracking runs the deferred bodies of the partner module on demand,
# so `.raises: []` holds across the cycle:
import mcyclic_effects {.cyclic.}

proc fa*(x: int): int {.raises: [].} = (if x > 0: fb(x - 1) else: 0)
proc ga*(): int = 7

echo fa(3), " ", gb()
