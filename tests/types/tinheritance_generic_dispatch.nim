discard """
  action: reject
  cmd: '''nim check --hints:off $options $file'''
  nimoutFull: true
  nimout: '''
tinheritance_generic_dispatch.nim(43, 5) Error: type mismatch: got <U>
but expected one of:
proc test(u: Union[string, RootObj])
  first type mismatch at position: 1
  required type for u: Union[system.string, system.RootObj]
  but expression 'U()' is of type: U

expression: test(U())
tinheritance_generic_dispatch.nim(45, 6) Error: type mismatch: got <T>
but expected one of:
proc test2(u: Union[int, float])
  first type mismatch at position: 1
  required type for u: Union[system.int, system.float]
  but expression 'T()' is of type: T

expression: test2(T())
tinheritance_generic_dispatch.nim(47, 6) Error: type mismatch: got <Union[system.string, system.RootObj]>
but expected one of:
proc test2(u: Union[int, float])
  first type mismatch at position: 1
  required type for u: Union[system.int, system.float]
  but expression 'Union[string, RootObj]()' is of type: Union[system.string, system.RootObj]

expression: test2(Union[string, RootObj]())
'''
"""

type
  Union[T, U] = object of RootObj

  U = object of Union[int, float]
  T = object of Union[string, RootObj]

proc test(u: Union[string, RootObj]) = discard
proc test2(u: Union[int, float]) = discard

test(T())
test(U())
test(Union[string, RootObj]())
test2(T())
test2(U())
test2(Union[string, RootObj]())