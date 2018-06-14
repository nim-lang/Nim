import macros
macro case_token(n: varargs[untyped]): untyped =
  # creates a lexical analyzer from regular expressions
  # ... (implementation is an exercise for the reader :-)
  nil

case_token: # this colon tells the parser it is a macro statement
of r"[A-Za-z_]+[A-Za-z_0-9]*":
  return tkIdentifier
of r"0-9+":
  return tkInteger
of r"[\+\-\*\?]+":
  return tkOperator
else:
  return tkUnknown

case_token: inc i

#bug #488

macro foo: typed =
  var exp = newCall("whatwhat", newIntLitNode(1))
  if compiles(getAst(exp)): return exp
  else: echo "Does not compute! (test OK)"

foo()
