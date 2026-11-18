discard """
  errormsg: "a 'var ref' parameter cannot be refined to a subtype"
  line: 15
"""

# bug #4312: `var ref Derived` is no subtype of `var ref Base`
type
  Base = ref object of RootObj
  Derived = ref object of Base

  BaseObj = object of RootObj
  DerivedObj = object of BaseObj

method f(a: var Base) {.base.} = discard
method f(a: var Derived) = discard

# fine: `var` objects are covariant
method g(a: var BaseObj) {.base.} = discard
method g(a: var DerivedObj) = discard
