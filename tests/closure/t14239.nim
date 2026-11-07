discard """

"""

# bug #14239
proc main =
  var x = 123
  proc withClosure = echo x
  proc withoutClosure = discard
  let _ = if true: withClosure else: withoutClosure # fine
  let _ = if true: (123, withClosure) else: (123, withoutClosure) # error
main()
