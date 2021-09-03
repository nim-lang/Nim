discard """
  action: compile
"""

{.push warningAsError[Effect]: on.}

{.experimental: "strictEffects".}

proc fn(a: int, p1, p2: proc()) {.effectsOf: p1.} =
  if a == 7:
    p1()
  if a<0:
    raise newException(ValueError, $a)

proc main() {.raises: [ValueError].} =
  fn(1, proc()=discard, proc() = raise newException(IOError, "foo"))
main()
