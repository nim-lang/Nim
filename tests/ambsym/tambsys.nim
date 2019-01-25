discard """
  output: ""
"""
# Test ambiguous symbols

import mambsys1, mambsys2

var
  v: mambsys1.TExport
mambsys2.foo(3) #OUT
