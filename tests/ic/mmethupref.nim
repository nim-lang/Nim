# Helper for tmethupref: a `{.base.}` method whose body contains a closure
# iterator that in turn contains a nested closure capturing a method-local.
# The capture forces an `up` reference chain (nested closure -> iterator env ->
# method env). The method also gets a dispatcher (a `copySym` clone that shares
# the method's body sub-tree, including the iterator). Under `nim ic` the
# dispatcher used to be treated as an owned runtime routine and lambda-lifted in
# the per-module lower stage, lifting the SHARED iterator a second time under a
# different owner identity -> "up references do not agree" / "could not determine
# closure type". See nifbackend.ownsRuntimeRoutine (sfDispatcher exclusion).

type Base* = ref object of RootObj
  val*: int

method compute*(b: Base): int {.base.} =
  var acc = b.val
  iterator steps(): int {.closure.} =
    proc bump() =
      acc += 1
    bump()
    bump()
    yield acc
  for s in steps():
    result = s
