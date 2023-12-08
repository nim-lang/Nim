discard """
  output: '''
int
float
int
float
'''
"""

block test_object:
  type Obj[T] = object

  proc `=destroy`[T](self: var Obj[T]) =
    echo T

  block:
    let intObj = default(Obj[int])

  block:
    let floatObj = default(Obj[float])

block test_distinct:
  type Obj[T] = distinct string

  proc `=destroy`[T](self: var Obj[T]) =
    echo T

  block:
    let intObj = default(Obj[int])

  block:
    let floatObj = default(Obj[float])
