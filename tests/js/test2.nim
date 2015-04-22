discard """
  output: '''foo
js 3.14
7'''
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

# #2495
type C = concept x

proc test(x: C, T: typedesc): T =
  cast[T](x)

echo 7.test(int8)
