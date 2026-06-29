discard """
  output: '''
-1
8
'''
  ccodecheck: "'console.log(-1); function fac_u' \\d+ '__tcodegendeclproc(n_p0)'"
"""
proc fac(n: int): int {.codegenDecl: "console.log(-1); function $2($3)".} =
  return n

echo fac(8)
