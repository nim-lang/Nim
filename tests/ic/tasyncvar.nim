discard """
output: '''2 true'''
"""

# Regression: NIF backend lowering of a routine whose nested closure captures a
# `var` parameter. nimbus-eth2 `LightClientManager.stop` is `{.async.}` with
# `self: var ...`; `nim ic` transformed it eagerly and failed with
# "'self' ... cannot be captured", while `nim c` never codegen'd the unused proc.

import masyncvar

var m = Mgr(x: 1)
stop(m, 0)
echo m.x, " ", m.done
