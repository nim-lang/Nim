import mmodsymasm

# The dead `else` branch qualifies a re-exported module (`mmodsymarm`) whose
# `foo` is gated out on this host: the module sym binds at template-definition
# but the member never resolves, so a dangling module-symbol reference survives
# into the serialized template body. Before the `ModMarker` fix this failed
# under `nim ic` with `symbol has no offset` when the consumer loaded this NIF.
template satAdd*(a, b: uint64): uint64 =
  when not defined(mmodSymFakeArch):
    mmodsymasm.mmodsymx86.foo(a, b)
  else:
    mmodsymasm.mmodsymarm.foo(a, b)
