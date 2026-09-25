discard """
  output: "ok"
"""

# A field use loaded from a NIF resolves to its object's field symbol, so NRVO
# sees that `state.pending` aliases the `a` argument of `mergeDamage`.
import mnrvofieldalias

var initial = Damage(kind: 1)
initial.payload[0] = 42
var state = State(pending: initial)
state.invalidate(Damage(kind: 0))

doAssert state.pending.kind == 1
doAssert state.pending.payload[0] == 42
echo "ok"
