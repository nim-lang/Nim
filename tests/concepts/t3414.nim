type
  View[T] = concept v
    v.empty is bool
    v.front is T
    popFront v

proc find(view: View; target: View.T): View =
  result = view

  while not result.empty:
    if view.front == target:
      return

    mixin popFront
    popFront result

proc popFront[T](s: var seq[T]) = discard
proc empty[T](s: seq[T]): bool = false

var s1 = @[1, 2, 3]
let s2 = s1.find(10)

