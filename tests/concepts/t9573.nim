# bug #9573: a tuple passed to a concept-constrained parameter
type Tuple2Like[A, B] = concept c
  c[0] is A
  c[1] is B

doAssert (int, char) is Tuple2Like[int, char]

func foo(x: Tuple2Like): int = x[0]

doAssert foo((3, 'a')) == 3
