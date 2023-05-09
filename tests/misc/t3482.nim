discard """
  action: reject
  nimout: "t3482.nim(13, 8) Error: undeclared identifier: 'output'"
"""
# bug #3482 (correct behavior since 1.4.0, cgen error in 1.2.0)
template foo*(body: typed) =
  if true:
    body

proc test =
  foo:
    var output = ""
  echo output.len

test()
