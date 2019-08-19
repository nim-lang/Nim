discard """
nimout: '''
testnewwarnings.nim(12, 14) Warning: implicit generics typedesc proc parameters are discouraged. Please use explicit generic parameters, for example:
proc foo3*[T, T1, T2](a: T; arg: typedesc[T1]; b: int; c: int; arg2: typedesc[T2]): T1 [Deprecated]
testnewwarnings.nim(15, 10) Warning: implicit generics typedesc proc parameters are discouraged. Please use explicit generic parameters, for example:
proc foo2[T1: SomeFloat](T: typedesc[T1]): T1 [Deprecated]
testnewwarnings.nim(18, 10) Warning: implicit generics typedesc proc parameters are discouraged. Please use explicit generic parameters, for example:
proc foo1[T1: SomeFloat](t: typedesc[T1]): T [Deprecated]
'''
"""

proc foo3*[T](a: T; arg: typedesc; b,c: int, arg2: typedesc): arg =
  discard

proc foo2(T: typedesc[SomeFloat]): T =
  discard

proc foo1(t: typedesc[SomeFloat]): int =
  discard

proc foo0[T](t: typedesc[T]): T =
  discard

proc baz(s: seq) =
  discard
