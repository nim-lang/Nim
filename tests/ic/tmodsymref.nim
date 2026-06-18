discard """
output: '''7'''
"""

# Regression test: a cross-module MODULE-symbol reference left as a dangling
# qualifier in a template body (here `mmodsymasm.mmodsymarm.foo` in a dead
# `when`-branch, reached via re-export) must load under `nim ic` instead of
# raising `symbol has no offset`. Mirrors nim-intops' `inlineasm.arm64.X` in
# nimbus-eth2. See compiler/ast2nif.nim `ModMarker`.

import mmodsymadd
echo satAdd(3'u64, 4'u64)
