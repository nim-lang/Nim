discard """
  output: "10"
"""

template something(name: untyped) =
  proc name(x: int) =
    var x = x # this one should not be rejected by the compiler (#5225)
    echo x

something(what)
what(10)

# bug #4750

type
  O = object
    i: int

  OP = ptr O

template alf(p: pointer): untyped =
  cast[OP](p)


proc t1(al: pointer) =
  var o = alf(al)

proc t2(alf: pointer) =
  var x = alf
  var o = alf(x)
