type
  StateA* = object
    w*: array[4, seq[int]]
  StateB* = object
    w*: array[4, seq[int]]
    extra*: int

iterator getP*(state: StateA | StateB, slot: int): int {.closure.} =
  if slot > 3: return
  for idx in state.w[slot]:
    yield idx

# The instance `getP[StateA]` is created (and offered) here, but only used from
# a generic caller: its body is transformed at `cg` time, so the lowered
# `.t.bif` keeps the instance's type without the lifted env param.
proc useHere*[T](s: T): int =
  for x in getP(s, 1): result += x

proc callHere*(s: StateA): int = useHere(s)
