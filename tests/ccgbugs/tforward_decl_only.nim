discard """
ccodecheck: "\\i !@('struct tyObject_MyRefObject'[0-z]+' {')"
output: "hello"
"""

# issue #7339 
# Test that MyRefObject is only forward declared as it used only by reference

import mymodule
type AnotherType = object
  f: MyRefObject 

let x = AnotherType(f: newMyRefObject("hello"))
echo $x.f


# bug #7363

type 
  Foo = object
    a: cint
  Foo2 = object
    b: cint
  Foo3 = object
    c:int

proc f(foo: ptr Foo, foo2: ptr Foo2, foo3: ptr Foo3): cint =
  if foo  != nil:  {.emit: "`result` = `foo`->a;".}
  if foo2 != nil: {.emit: [result, " = ", foo2[], ".b;"].}
  if foo3 != nil:  {.emit: "`result` = `foo3[]`.c + `foo3.c`;".}

discard f(nil, nil, nil)


# bug #7392
var x1: BaseObj
var x2 = ChildObj(x1)
