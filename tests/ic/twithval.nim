discard """
output: '''7'''
"""

# Regression: expanding a NIF-loaded generic template that injects a typed
# ident (`let value {.inject.} = temp.get()`) into the caller's body.
# Mirrors libp2p `Opt.withValue` which failed compiling nimbus under `nim ic`
# with "expression '' has no type" / "'let' symbol requires an initialization".

import mwithval

type Cfg = object
  n: int

var o = some(Cfg(n: 7))
o.withValue(cfg):
  echo cfg.n
