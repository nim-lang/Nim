discard """
  msg: '''
int
float
TFoo
TFoo
'''
"""

import typetraits

type 
  TFoo = object
    x, y: int

  TBar = tuple
    x, y: int

template good(e: expr) =
  static: assert(compiles(e))

template bad(e: expr) =
  static: assert(not compiles(e))

proc genericParamRepeated[T: typedesc](a: T, b: T) =
  static:
    echo a.name
    echo b.name

good(genericParamRepeated(int, int))
good(genericParamRepeated(float, float))

bad(genericParamRepeated(string, int))
bad(genericParamRepeated(int, float))

proc genericParamOnce[T: typedesc](a, b: T) =
  static:
    echo a.name
    echo b.name

good(genericParamOnce(int, int))
good(genericParamOnce(TFoo, TFoo))

bad(genericParamOnce(string, int))
bad(genericParamOnce(TFoo, float))

proc typePairs(A, B: type1; C, D: type2) = nil

good(typePairs(int, int, TFoo, TFOO))
good(typePairs(TBAR, TBar, TBAR, TBAR))
good(typePairs(int, int, string, string))

bad(typePairs(TBAR, TBar, TBar, TFoo))
bad(typePairs(string, int, TBAR, TBAR))

proc typePairs2[T: typedesc, U: typedesc](A, B: T; C, D: U) = nil

good(typePairs2(int, int, TFoo, TFOO))
good(typePairs2(TBAR, TBar, TBAR, TBAR))
good(typePairs2(int, int, string, string))

bad(typePairs2(TBAR, TBar, TBar, TFoo))
bad(typePairs2(string, int, TBAR, TBAR))

proc dontBind(a: typedesc, b: typedesc) =
  static:
    echo a.name
    echo b.name

good(dontBind(int, float))
good(dontBind(TFoo, TFoo))

proc dontBind2(a, b: typedesc) = nil

good(dontBind2(int, float))
good(dontBind2(TBar, int))

proc bindArg(T: typedesc, U: typedesc, a, b: T, c, d: U) = nil

good(bindArg(int, string, 10, 20, "test", "nest"))
good(bindArg(int, int, 10, 20, 30, 40))

bad(bindArg(int, string, 10, "test", "test", "nest"))
bad(bindArg(int, int, 10, 20, 30, "test"))
bad(bindArg(int, string, 10.0, 20, "test", "nest"))
bad(bindArg(int, string, "test", "nest", 10, 20))

