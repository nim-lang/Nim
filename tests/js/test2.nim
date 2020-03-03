discard """
  output: '''foo
js 3.14
7
1
-21550
-21550'''
"""

# This file tests the JavaScript generator

doAssert getCurrentException() == nil
doAssert getCurrentExceptionMsg() == ""

#  #335
proc foo() =
  var bar = "foo"
  proc baz() =
    echo bar
  baz()
foo()

# #376
when not defined(js):
  proc foo(val: float): string = "no js " & $val
else:
  proc foo(val: float): string = "js " & $val

echo foo(3.14)

# #2495
type C = concept x

proc test(x: C, T: typedesc): T =
  cast[T](x)

echo 7.test(int8)

# #4222
const someConst = [ "1"]

proc procThatRefersToConst() # Forward decl
procThatRefersToConst() # Call bar before it is defined

proc procThatRefersToConst() =
  var i = 0 # Use a var index, otherwise nim will constfold foo[0]
  echo someConst[i] # JS exception here: foo is still not initialized (undefined)

# bug #6753
let x = -1861876800
const y = 86400
echo (x - (y - 1)) div y # Now gives `-21550`

proc foo09() =
    let x = -1861876800
    const y = 86400
    echo (x - (y - 1)) div y # Still gives `-21551`
foo09()
