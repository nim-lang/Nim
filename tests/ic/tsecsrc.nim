discard """
output: '''1'''
"""

# Regression: confutils `ConfType.load(secondarySources = proc(..., sources:
# ref SecondarySources) ...)` under `nim ic`. The `load` template is NIF-loaded;
# its expansion must run the `generateSecondarySources` macro so the ident
# `SecondarySources` is in scope for the untyped callback. nimbus-eth2 failed
# with "undeclared identifier: 'SecondarySources'".

import msecsrc

type Conf = object

echo Conf.load(
  secondarySources = proc(config: Conf, sources: ref SecondarySources) =
    sources.data = 1
)
