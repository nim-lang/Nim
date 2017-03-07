discard """
  output: '''monkey'''
"""
# bug #5478
template creature*(name: untyped) =
  type
    name*[T] = object
      color: T

  proc `init name`*[T](c: T): name[T] =
    mixin transform
    transform()

creature(Lion)

type Monkey* = object
proc transform*() =
  echo "monkey"

var
  m: Monkey
  y = initLion(m)  #this one failed to compile
