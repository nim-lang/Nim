discard """
action: compile
"""

# bug #16471

type P[T] = tuple[val: T]
converter toP*[V, T](v: V): P[T] = discard
let a = 1 + 1
