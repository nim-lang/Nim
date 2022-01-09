discard """
  cmd: "nim check --hints:off --warnings:off $file"
  action: "reject"
  nimout:'''
tstatic_constrained.nim(41, 20) Error: cannot instantiate MyOtherType [type declared in tstatic_constrained.nim(27, 3)]
got: <typedesc[int], int literal(10)>
but expected: <T: float or string, Y>
tstatic_constrained.nim(41, 20) Error: cannot instantiate MyOtherType [type declared in tstatic_constrained.nim(27, 3)]
got: <typedesc[int], int literal(10)>
but expected: <T: float or string, Y>
tstatic_constrained.nim(41, 29) Error: object constructor needs an object type [proxy]
tstatic_constrained.nim(41, 29) Error: expression '' has no type (or is ambiguous)
tstatic_constrained.nim(42, 20) Error: cannot instantiate MyOtherType [type declared in tstatic_constrained.nim(27, 3)]
got: <typedesc[byte], uint8>
but expected: <T: float or string, Y>
tstatic_constrained.nim(42, 20) Error: cannot instantiate MyOtherType [type declared in tstatic_constrained.nim(27, 3)]
got: <typedesc[byte], uint8>
but expected: <T: float or string, Y>
tstatic_constrained.nim(42, 32) Error: object constructor needs an object type [proxy]
tstatic_constrained.nim(42, 32) Error: expression '' has no type (or is ambiguous)
'''
"""

type 
  MyType[T; X: static T] = object
    data: T
  MyOtherType[T: float or string, Y: static T] = object

func f[T,X](a: MyType[T,X]): MyType[T,X] =
  when T is string:
    MyType[T,X](data: a.data & X)
  else:
    MyType[T,X](data: a.data + X)

discard MyType[int, 2](data: 1)
discard MyType[string, "Helelello"](data: "Hmmm")
discard MyType[int, 2](data: 1).f()
discard MyType[string, "Helelello"](data: "Hmmm").f()
discard MyOtherType[float, 1.3]()
discard MyOtherType[string, "Hello"]()
discard MyOtherType[int, 10]()
discard MyOtherType[byte, 10u8]()