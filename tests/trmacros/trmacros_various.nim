discard """
output: '''
12false3ha
21
optimized
'''
"""

import macros, pegs


block arglist:
  proc f(x: varargs[string, `$`]) = discard
  template optF{f(x)}(x: varargs[untyped]) =
    writeLine(stdout, x)

  f 1, 2, false, 3, "ha"



block tcse:
  template cse{f(a, a, x)}(a: typed{(nkDotExpr|call|nkBracketExpr)&noSideEffect},
                         f: typed, x: varargs[typed]): untyped =
    let aa = a
    f(aa, aa, x)+4

  var
    a: array[0..10, int]
    i = 3
  doAssert a[i] + a[i] == 4



block hoist:
  template optPeg{peg(pattern)}(pattern: string{lit}): Peg =
    var gl {.global, gensym.} = peg(pattern)
    gl
  doAssert match("(a b c)", peg"'(' @ ')'")
  doAssert match("W_HI_Le", peg"\y 'while'")



block tmatrix:
  type
    TMat = object
      dummy: int

  proc `*`(a, b: TMat): TMat = nil
  proc `+`(a, b: TMat): TMat = nil
  proc `-`(a, b: TMat): TMat = nil
  proc `$`(a: TMat): string = result = $a.dummy
  proc mat21(): TMat =
    result.dummy = 21

  macro optOps{ (`+`|`-`|`*`) ** a }(a: TMat): untyped =
    result = newCall(bindSym"mat21")

  #macro optPlus{ `+` * a }(a: varargs[TMat]): expr =
  #  result = newIntLitNode(21)

  var x, y, z: TMat
  echo x + y * z - x



block tnoalias:
  template optslice{a = b + c}(a: untyped{noalias}, b, c: untyped): typed =
    a = b
    inc a, c
  var
    x = 12
    y = 10
    z = 13
  x = y+z
  doAssert x == 23



block tnoendlessrec:
  # test that an endless recursion is avoided:
  template optLen{len(x)}(x: typed): int = len(x)

  var s = "lala"
  doAssert len(s) == 4



block tstatic_t_bug:
  # bug #4227
  type Vector64[N: static[int]] = array[N, int]

  proc `*`[N: static[int]](a: Vector64[N]; b: float64): Vector64[N] =
    result = a

  proc `+=`[N: static[int]](a: var Vector64[N]; b: Vector64[N]) =
    echo "regular"

  proc linearCombinationMut[N: static[int]](a: float64, v: var Vector64[N], w: Vector64[N])  {. inline .} =
    echo "optimized"

  template rewriteLinearCombinationMut{v += `*`(w, a)}(a: float64, v: var Vector64, w: Vector64): auto =
    linearCombinationMut(a, v, w)

  proc main() =
    const scaleVal = 9.0
    var a, b: Vector64[7]
    a += b * scaleval

  main()

