discard """
output: '''
2
2
2
'''
"""

# bug 2659

type
  GenProcType[T,U] = proc(x:T, y:var U)
  IntProcType = proc(x:int, y:var int)

proc mult(x:int, y:var int) =
  y = 2 * x

when true:

  var input = 1
  var output = 0

  var someIntProc:IntProcType = mult
  var someGenProc:GenProcType[int,int] = mult

  mult(input, output)
  echo output

  someIntProc(input, output)
  echo output

  # Uncommenting causes an error in the C compiler.
  someGenProc(input, output)
  echo output
