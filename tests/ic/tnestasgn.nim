discard """
output: '''hi'''
"""

# Regression test, minimized from a nimbus-eth2 `nim ic` crash by
# https://github.com/nim-lang/Nim/pull/26106 (the only one of that PR's eight
# repros that reproduces on its own base).
#
# A NIF-loaded routine's body is installed as a `nfLazyBody` placeholder. The
# placeholder used to carry the REAL body kind while holding no children, which
# breaks the compiler's most basic invariant — a node's kind implies its arity.
# `trees.getPotentialWrites` walks the outer routine because it has a `sink`
# parameter, reaches the nested proc's body under `of nkAsgn`, and reads
# `n[0]`/`n[1]` as every such reader is entitled to: "index out of bounds, the
# container is empty [IndexDefect]".

import mnestasgn
consume("hi")
