discard """
  output: '''
declare fac_26003(n_26005)
8
'''
"""
proc fac(n: int): int {.codegenDecl: "console.log('declare $2($3)'); function $2($3)".} =
  return n

echo fac(8)
