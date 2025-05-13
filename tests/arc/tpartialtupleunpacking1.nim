discard """
  output: '''
destroyed
'''
"""

# issue #24947

type Foo = object

proc `=destroy`(x: Foo) =
  echo "destroyed"

proc go(): void =
  let a = (1,2,3, Foo())
  var b,c,d: int
  (b,c,d,_) = a # assignment unpacking

go()
