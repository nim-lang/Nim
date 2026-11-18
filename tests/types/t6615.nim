discard """
  targets: "c cpp js"
  output: '''
true
false
'''
"""

# bug #6615: `nil` default for a param of the type being defined
type
  SomeType* = ref object of RootRef
    poll*: proc(variable: SomeType = nil)

var x = SomeType()
x.poll = proc(variable: SomeType = nil) = echo variable == nil
x.poll()
x.poll(x)
