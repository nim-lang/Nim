discard """
  output: '''ok'''
"""

import typetraits

type
  TFoo = object
    x, y: int

  TBar = tuple
    x, y: int

template accept(e) =
  static: assert(compiles(e))

template reject(e) =
  static: assert(not compiles(e))

proc genericParamRepeated[T: typedesc](a: T, b: T) =
  static:
    echo a.name, " ", b.name

accept genericParamRepeated(int, int)
accept genericParamRepeated(float, float)

reject genericParamRepeated(string, int)
reject genericParamRepeated(int, float)

proc genericParamOnce[T: typedesc](a, b: T) =
  static:
    echo a.name, " ", b.name

accept genericParamOnce(int, int)
accept genericParamOnce(TFoo, TFoo)

reject genericParamOnce(string, int)
reject genericParamOnce(TFoo, float)

type
  type1 = typedesc
  type2 = typedesc

proc typePairs(A, B: type1; C, D: type2) = discard

accept typePairs(int, int, TFoo, TFOO)
accept typePairs(TBAR, TBar, TBAR, TBAR)
accept typePairs(int, int, string, string)

reject typePairs(TBAR, TBar, TBar, TFoo)
reject typePairs(string, int, TBAR, TBAR)

proc typePairs2[T: typedesc, U: typedesc](A, B: T; C, D: U) = discard

accept typePairs2(int, int, TFoo, TFOO)
accept typePairs2(TBAR, TBar, TBAR, TBAR)
accept typePairs2(int, int, string, string)

reject typePairs2(TBAR, TBar, TBar, TFoo)
reject typePairs2(string, int, TBAR, TBAR)

proc dontBind(a: typedesc, b: typedesc) =
  static:
    echo a.name, " ", b.name

accept dontBind(int, float)
accept dontBind(TFoo, TFoo)

proc dontBind2(a, b: typedesc) = discard

accept dontBind2(int, float)
accept dontBind2(TBar, int)

proc bindArg(T: typedesc, U: typedesc, a, b: T, c, d: U) = discard

accept bindArg(int, string, 10, 20, "test", "nest")
accept bindArg(int, int, 10, 20, 30, 40)

reject bindArg(int, string, 10, "test", "test", "nest")
reject bindArg(int, int, 10, 20, 30, "test")
reject bindArg(int, string, 10.0, 20, "test", "nest")
reject bindArg(int, string, "test", "nest", 10, 20)

echo "ok"

#11058:
template test(S: type, U: type) =
  discard

test(int, float)

proc test2(S: type, U: type) =
  discard

test2(float, int)
