discard """
  output: '''
-1
8
'''
  ccodecheck: "'console.log(-1); function fac_' \\d+ '(n_' \\d+ ')'"
"""
proc fac(n: int): int {.codegenDecl: "console.log(-1); function $2($3)".} =
  return n

echo fac(8)
