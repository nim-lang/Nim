discard """
  cmd: "nim c --errorMax:0 $options $file"
  errormsg: ""
  nimout: '''
t8794.nim(24, 14) Error: undeclared field: 'a2'
t8794.nim(33, 27) Error: undeclared field: 'a3'
'''
"""











## line 20
type Foo = object
  a1: int

discard Foo().a2

type Foo2 = Foo
var x2: Foo2()

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
