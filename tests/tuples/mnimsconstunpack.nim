proc foo(): tuple[a, b: string] =
  result = ("a", "b")

const (a, b*) = foo()
