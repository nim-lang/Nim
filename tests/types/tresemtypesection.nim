macro foo(x: typed) =
  result = x

foo:
  type
    Generic1[T] = object
    Generic2[T] = ref int
    Generic3[T] = ref Generic1[T]
    Generic4[T] = Generic2[T]
    GenericInst1 = Generic1[int]
    GenericInst2 = Generic2[int]
    GenericInst3 = Generic3[int]
    GenericInst4 = Generic4[int]

block: # issue #24898
  type V[W] = object
  template g(d: int) = discard d
  g((; type J = V[int]; 0))
