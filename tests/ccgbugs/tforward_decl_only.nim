discard """
ccodecheck: "\\i !@('struct tyObject_MyRefObject'[0-z]+' {')"
output: "hello"
"""

# issue #7339 
# Test that MyRefObject is only forward declared as it used only by reference

import mymodule
type AnotherType = object
  f: MyRefObject 

let x = AnotherType(f: newMyRefObject("hello"))
echo $x.f

