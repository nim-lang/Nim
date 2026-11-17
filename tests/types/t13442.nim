discard """
  output: '''
3 ["a", "b", "c"]
3 ["a", "b", "c"]
2 ["q", "r"]
'''
"""

# bug #13442: converting to an openArray type with an unspecified element type
proc foo(x: varargs[string]) = echo x.len, " ", x
foo(varargs(@["a", "b", "c"]))
foo(openarray[auto](@["a", "b", "c"]))
let s = @["q", "r"]
foo(openArray(s))
