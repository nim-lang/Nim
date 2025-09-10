discard """
  action: reject
"""

# issue #15637

template foo(x: typed) =
  block:
    x
    x

proc bar =
  foo:
    block:
      var a = 0
    var a = 0

bar()
