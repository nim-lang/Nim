template declareInScope(x: expr, t: typeDesc): stmt = 
  var x: t
  
template declareInNewScope(x: expr, t: typeDesc): stmt = 
  # open a new scope:
  block: 
    var x: t

declareInScope(a, int)
a = 42  # works, `a` is known here

declareInNewScope(b, int)
b = 42  #ERROR_MSG undeclared identifier: 'b'

