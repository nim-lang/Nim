discard """
  output: '''true'''
"""

# bug #4673
type
  BaseObj[T] = ref object of RootObj
  SomeObj = ref object of BaseObj[int]

proc doSomething[T](o: BaseObj[T]) =
  echo "true"
var o = new(SomeObj)
o.doSomething() # Error: cannot instantiate: 'T'
