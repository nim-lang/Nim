discard """
cmd: "nim check $options --hints:off $file"
action: "reject"
nimout:'''
tpointerprocs.nim(15, 11) Error: 'foo' doesn't have a concrete type, due to unspecified generic parameters.
tpointerprocs.nim(27, 11) Error: cannot instantiate: 'foo[int]'; got 1 typeof(s) but expected 2
tpointerprocs.nim(27, 14) Error: expression 'foo[int]' has no type (or is ambiguous)
tpointerprocs.nim(28, 11) Error: expression 'bar' has no type (or is ambiguous)
'''
"""

block:
  proc foo(x: int | float): float = result = 1.0
  let
    bar = foo
    baz = bar

block:
  proc foo(x: int | float): float = result = 1.0
  let
    bar = foo[int]
    baz = bar

block:
  proc foo(x: int | float, y: int or string): float = result = 1.0
  let
    bar = foo[int]
    baz = bar