discard """
  output: '''
2 true
3 true
1 false
3 true
4 false
1 true
'''
"""

# bug #9996: an empty `varargs[untyped]` forwarded to a proc with defaults
type
  SomeObject = object

proc procWithDefaults(o: SomeObject, x = 1, y = true) =
  echo x, " ", y

template myTemplate(T: type, args: varargs[untyped]) =
  var obj: T
  obj.procWithDefaults(args)

myTemplate(SomeObject, 2)
myTemplate(SomeObject, 3, true)
myTemplate(SomeObject, y = false)
myTemplate(SomeObject, x = 3)
myTemplate(SomeObject, y = false, x = 4)
myTemplate(SomeObject)
