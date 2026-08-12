discard """
  action: run
  output: "callback ran"
"""

# Pins the current behaviour of `.forbids` on a proc *body* whose own body makes
# an indirect call with unknown effects (refs #25978).
#
# The callee is widened to RootEffect by `assumeTheWorst`. A whitelist (`tags`)
# rejects that, since RootEffect is not among the listed tags. A blacklist
# (`forbids`) accepts it, because the check asks whether RootEffect is a subtype
# of the forbidden effect, while it is an ancestor of it instead.
#
# Replacing `{.forbids: [MyEffect].}` below with `{.tags: [].}` is rejected at
# compile time, so the two pragmas disagree on identical input. This test only
# records the current state; it takes no position on which side is correct.
#
# Unrelated to the diagnostic wording covered by #26005: here no message is
# produced at all.
#
# If the behaviour is changed deliberately, this test is expected to fail and
# should be updated to the new expectation.

type MyEffect = object of RootEffect

proc viaCallback(p: proc(i: int)) {.forbids: [MyEffect].} =
  p(1)

proc hasEffect(i: int) {.tags: [MyEffect].} =
  echo "callback ran"

viaCallback(hasEffect)
