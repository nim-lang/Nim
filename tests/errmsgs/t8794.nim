discard """
  cmd: "nim check $options $file"
"""

## issue #8794

import m8794

type Foo = object
  a1: int

discard Foo().a2 #[tt.Error
             ^ undeclared field: 'a2' for type t8794.Foo [type declared in t8794.nim(9, 6)]]#

type Foo3b = Foo3
var x2: Foo3b

proc getFun[T](): T =
  var a: T
  a

discard getFun[type(x2)]().a3 #[tt.Error
                          ^ undeclared field: 'a3' for type m8794.Foo3 [type declared in m8794.nim(1, 6)]]#
