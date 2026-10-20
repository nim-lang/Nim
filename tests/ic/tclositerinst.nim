discard """
  output: '''3 3 9'''
"""

# NOTE: `--debugger:native` (Itanium mangling, which encodes the parameter
# types into the C name) lives in the sibling `tclositerinst_temp.nim.cfg`.

# Regression test: under `nim ic` a loaded routine shares its AST params with
# its proc type's `n`, so when lambda lifting adds the hidden `:envP` param to
# a closure iterator instance, the param leaks into the TYPE, but only in the
# processes where lifting has already run when the instance gets its C name.
# The Itanium name of `getP[StateA]` then included `ref Env` in some TUs and not
# in others, so the one definition emitted by its home module was referenced
# under names that nobody defines. Fixed by skipping the env param
# (`astdef.isClosureEnvParam`) in the mangler and in the backend type keys, as
# `genProcParams` and `sighashes` already did.

import mclositlib, mclosita, mclositb

var a = StateA(w: [@[1, 2], @[3], @[], @[]])
echo fa(a), " ", callHere(a), " ", ga(a)
