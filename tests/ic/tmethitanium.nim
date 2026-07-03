discard """
  output: '''woof
generic-animal-sound
generic-animal-sound/woof'''
"""

# NOTE: the `--debugger:native` that triggers the Itanium mangling lives in the
# sibling `tmethitanium_temp.nim.cfg` (the IC test harness compiles the generated
# `_temp.nim` and does not thread a `matrix`/`$options` switch into the cg
# children; a project cfg is read by the driver, which forwards it).

# Regression test: under `nim ic --debugger:native` the per-module backend uses
# the Itanium C name mangling, which encodes the signature and drops the
# `disamb`. A `{.base.}` method (owner module mmethanimal) and its whole-program
# dispatcher (synthesized into this main module) then share a signature, so the
# clean-name uniqueness probe (`m.g.mangledPrcs`) — which only sees the current
# module — gave the base a clean name at its owner but an unstable
# `itemId.item`-based `speak_u<n>` at each demander. Result: the base was defined
# once (clean) but referenced under names defined nowhere ("undefined reference
# to speak_u1") while the dispatcher collided with the clean base ("multiple
# definition of speak"). This was the bulk of nimbus-eth2's libp2p method link
# failures under `nim ic`. Fixed by making the Itanium scheme use the stable
# `disamb` (ccgutils.makeUnique) and always uniquify routine names under the
# per-module backend (ccgtypes.fillBackendName), plus forwarding
# `--debugger:native` to the cg children (deps.computeForwardedArgs).

import mmethanimal, mmethdog

let a: Animal = Dog()
echo speak(a)            # dispatches -> override
let b: Animal = Animal()
echo speak(b)            # dispatches -> base body
echo speakBoth(Dog())    # procCall to base from non-owner module
