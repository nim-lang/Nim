discard """
  output: "10"
"""

template something(name: untyped) =
  proc name(x: int) =
    var x = x # this one should not be rejected by the compiler (#5225)
    echo x

something(what)
what(10)
