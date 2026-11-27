# bug #11154: the converter of a `varargs[T, conv]` parameter is found when
# it is not visible at the call site
import m11154

doAssert test(0..1) == "0..1"
doAssert implicitConvert(2..3, 4..5) == "2..34..5"
