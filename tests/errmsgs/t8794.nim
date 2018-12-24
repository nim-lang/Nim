discard """
  cmd: "nim c --errorMax:0 $options $file"
  errormsg: ""
  nimout: '''
t8794.nim(29, 14) Error: undeclared field: 'a2' for type t8794.Foo[declared in t8794.nim(26, 5)]
t8794.nim(38, 27) Error: undeclared field: 'a3' for type m8794.Foo3[declared in m8794.nim(1, 5)]
'''
"""











## line 20

## issue #8794

import m8794

type Foo = object
  a1: int

discard Foo().a2

type Foo3b = Foo3
var x2: Foo3b

proc getFun[T](): T =
  var a: T
  a

discard getFun[type(x2)]().a3

#[
Note: this test also shows that we can specify only the lines we care about testing
in nimout with tests expected to fail, instead of all the lines (which could
contain unwanted compiler messages that may eventually get fixed).
This makes the test more forward compatible, in case unwanted stuff gets
removed in the future (without breaking this test).
It also allows the test to be more focused in what it checks (eg, we
dont' have to show hints etc).

For example, nim check currently outputs all these lines, but this test only
cares about a (non-contiguous) subset.

t8794.nim(24, 14) Error: undeclared field: 'a2'
t8794.nim(24, 14) Error: undeclared field: '.'
t8794.nim(24, 14) Error: expression '.' cannot be called
t8794.nim(27, 13) Error: expected type, but got: Foo2()
t8794.nim(33, 27) Error: undeclared field: 'a3'
t8794.nim(33, 27) Error: undeclared field: '.'
t8794.nim(33, 27) Error: expression '.' cannot be called

]#
