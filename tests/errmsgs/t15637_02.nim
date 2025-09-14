discard """
  action: reject
"""

# issue #15637

template foo(x: typed) =
  x
  x

proc bar =
  foo:
    var a = 1

bar()
