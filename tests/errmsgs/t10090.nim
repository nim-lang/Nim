discard """
  errormsg: "cannot assign 'placeholderMacro()' to variable. Is this an empty macro?"
  line: 7
"""

macro placeholderMacro: untyped = discard
var a = placeholderMacro()
