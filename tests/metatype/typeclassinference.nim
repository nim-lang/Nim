import typetraits

type
  Vec[N: static[int]; T] = distinct array[N, T]

var x = Vec([1, 2, 3])

static:
  assert x.type.name == "Vec[static[int](3), int]"

