discard """
  output: '''foo
js 3.14'''
"""

# This file tests the JavaScript generator

#  #335
proc foo() =
  var bar = "foo"
  proc baz() =
    echo bar
  baz()
foo()

# #376
when not defined(JS):
  proc foo(val: float): string = "no js " & $val
else:
  proc foo(val: float): string = "js " & $val

echo foo(3.14)
