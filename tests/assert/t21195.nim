discard """
  matrix: "--verbosity:0 --os:standalone --mm:none"
"""
# bug #21195
var n = 11
assert(n == 12)
