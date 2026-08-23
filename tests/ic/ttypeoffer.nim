discard """
output: '''ok'''
"""

# Regression test for the `(toffer …)` generic-TYPE-instance sharing across the
# NIF boundary. A `tyGenericInst` whose structure (here an `array` bound) depends
# on a `mixin`/`compiles()` resolved at the instantiation site must be REUSED
# from the module that created it, not re-instantiated in a consumer whose import
# scope flips the `compiles()` and so bakes a different bound. Mirrors the SSZ
# `HashArray[8192, Gwei]` `sizeof` divergence in nimbus-eth2. Before the fix this
# failed under `nim ic` with `doAssert sizeof(StateA) == sizeof(StateB)`.

import mtoffuser
check()
