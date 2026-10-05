discard """
  matrix: "--mm:refc; --mm:orc"
  ccodecheck: "\\i !@('nimZeroMem(((void*) ((&')"
  output: '''
1 2 3 4 5 6 7 8
0 0 0 0
'''
"""

# bug #23383: a result passed via hidden pointer was zeroed by the caller
# and then again by the callee. Only the callee zeros it now: 'main' must
# not zero 'x' and 'y' before passing them as 'Result'.
import std/strutils

type
  Big = object
    a, b, c, d, e, f, g, h: int

proc mk(): Big =
  result = Big(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: 8)

proc partial(x: int): Big =
  result.a = x

proc main =
  let x = mk()
  echo [x.a, x.b, x.c, x.d, x.e, x.f, x.g, x.h].join(" ")
  var y = partial(0)
  echo [y.a, y.b, y.c, y.h].join(" ")

main()
