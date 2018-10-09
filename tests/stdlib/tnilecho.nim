discard """
  output: ""
"""

var x = @["1", "", "3"]
doAssert $x == """@["1", "", "3"]"""
