discard """
  action: reject
  errormsg: "type expected"
  file: "iterators.nim"
"""


template b(j: untyped) = j
template m() = discard

b:
  for t, f in @[]:
    m()
