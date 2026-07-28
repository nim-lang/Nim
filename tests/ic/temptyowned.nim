discard """
output: '''called false
done'''
"""

# Regression test for the per-module IC backend dropping an owned routine whose
# body folds to `nkEmpty`. `memptyowned.emptyOwned` is a real, concrete, owned
# proc with an empty body; `memptycaller.callEmpty` references it across a module
# boundary. The owning module's `ownsRuntimeRoutine` seeding used to reject any
# routine with an `nkEmpty` body, so nobody emitted `emptyOwned` -> undefined
# reference at link (mirrors Nimbus `ncli` linking `extras.incInternalErrors`).
# Whole-program cgen always emits it as `void emptyOwned(void){}`; the per-module
# backend must too.

import memptycaller

callEmpty(false)
echo "done"
