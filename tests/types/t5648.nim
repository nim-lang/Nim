discard """
  output: '''
ptr Foo
'''
joinable: false
"""
# not joinable because it causes out of memory with --gc:boehm

# issue #5648

import typetraits

type Foo = object
  bar: int

proc main() =
  var f = create(Foo)
  f.bar = 3
  echo f.type.name

  discard realloc(f, 0)

  var g = Foo()
  g.bar = 3

var
  mainPtr = cast[pointer](main)
  mainFromPtr = cast[typeof(main)](mainPtr)

doAssert main == mainFromPtr

main()
