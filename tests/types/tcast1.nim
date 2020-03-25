discard """
output: '''
@[1.0, 2.0, 3.0]
@[1.0, 2.0, 3.0]
'''
"""

# bug #6406

import sequtils

proc remap1(s: seq[int], T: typedesc): seq[T] =
  s.map do (x: int) -> T:
    x.T

proc remap2[T](s: seq[int], typ: typedesc[T]): seq[T] =
  s.map do (x: int) -> T:
    x.T

echo remap1(@[1,2,3], float)
echo remap2(@[1,2,3], float)


#--------------------------------------------------------------------
# conversion to bool, issue #13744
proc test_conv_to_bool = 
  var 
    i0 = 0
    i1 = 1
    ih = high(uint)
    il = low(int)

    f0 = 0.0
    f1 = 1.0
    fh = Inf
    fl = -Inf
    f_nan = NaN

  doAssert(bool(i0) == false)
  doAssert(bool(i1) == true)
  doAssert(bool(-i1) == true)
  doAssert(bool(il) == true)
  doAssert(bool(ih) == true)

  doAssert(bool(f0) == false)
  doAssert(bool(-f0) == false)
  doAssert(bool(f1) == true)
  doAssert(bool(-f1) == true)
  doAssert(bool(fh) == true)
  doAssert(bool(fl) == true)
  doAssert(bool(fnan) == true) # NaN to bool gives true according to standard


static:
  doAssert(bool(0) == false)
  doAssert(bool(-1) == true)
  doAssert(bool(2) == true)
  doAssert(bool(NaN) == true)
  doAssert(bool(0.0) == false)
  doAssert(bool(-0.0) == false)
  test_conv_to_bool()
test_conv_to_bool()

