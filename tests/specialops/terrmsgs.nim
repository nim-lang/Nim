discard """
action: reject
cmd: '''nim check $options $file'''
matrix: "; -d:testWithout"
"""

when not defined(testWithout): # test for same errors before and after
  {.experimental: "dotOperators".}
  {.experimental: "callOperator".}

# issue #13063

block:
  type Foo = object
  type Bar = object
    x1: int
  var b: Bar
  block:
    template `.`(a: Foo, b: untyped): untyped = 123
    echo b.x #[tt.Error
          ^ undeclared field: 'x' for type terrmsgs.Bar [type declared in terrmsgs.nim(15, 8)]]#
  block:
    template `.()`(a: Foo, b: untyped): untyped = 123
    echo b.x() #[tt.Error
          ^ attempting to call undeclared routine: 'x']#
  block:
    template `.=`(a: Foo, b: untyped, c: untyped) = b = c
    b.x = 123 #[tt.Error
        ^ undeclared field: 'x=' for type terrmsgs.Bar [type declared in terrmsgs.nim(15, 8)]]#
    # yeah it says x= but does it matter in practice
  block:
    template `()`(a: Foo, b: untyped, c: untyped) = echo "something"

    # completely undeclared::
    xyz(123) #[tt.Error
    ^ undeclared identifier: 'xyz']#

    # already declared routine:
    min(123) #[tt.Error
       ^ type mismatch: got <int literal(123)>]#

    # non-routine type shows `()` overloads:
    b(123) #[tt.Error
     ^ attempting to call routine: 'b']#

    echo b.x #[tt.Error
          ^ undeclared field: 'x' for type terrmsgs.Bar [type declared in terrmsgs.nim(15, 8)]]#
    echo b.x() #[tt.Error
          ^ attempting to call undeclared routine: 'x']#

# issue #7777

import macros

block:
  type TestType = object
    private_field: string

  when false:
    template getField(obj, field: untyped): untyped = obj.field

  macro `.`(obj: TestType, field: untyped): untyped =
    let private = newIdentNode("private_" & $field)
    result = quote do:
      `obj`.getField(`private`) #[tt.Error
           ^ attempting to call undeclared routine: 'getField']#

  var tt: TestType
  discard tt.field

block: # related to issue #6981
  proc `()`(a:string, b:string):string = a & b
  proc mewSeq[T](a,b:int)=discard
  proc mewSeq[T](c:int)= discard
  mewSeq[int]() #[tt.Error
             ^ type mismatch: got <>]#
