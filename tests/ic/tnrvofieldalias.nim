discard """
  output: "ok"
"""

# Field uses loaded from a NIF are separate `skField` stubs; NRVO must still see
# that `state.pending` aliases the `a` argument of `mergeDamage`.
import mnrvofieldalias

var initial = Damage(kind: 1)
initial.payload[0] = 42
var state = State(pending: initial)
state.invalidate(Damage(kind: 0))

doAssert state.pending.kind == 1
doAssert state.pending.payload[0] == 42
echo "ok"
