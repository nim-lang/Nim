# Gated out on every host (mmodSymFakeArch is never defined): `foo` does NOT
# exist here, so a qualified `…mmodsymarm.foo` cannot resolve to the proc and
# leaves the bare re-exported MODULE symbol dangling in the template body.
when defined(mmodSymFakeArch):
  func foo*(a, b: uint64): uint64 = a + b
