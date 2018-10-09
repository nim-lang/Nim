discard """
output: '''proc foo[T, N: static[int]]()
proc foo[T; N: static[int]]()'''
"""
import macros

macro test():string =
    let expr0 = "proc foo[T, N: static[int]]()"
    let expr1 = "proc foo[T; N: static[int]]()"

    $toStrLit(parseExpr(expr0)) & "\n" & $toStrLit(parseExpr(expr1))
    
echo test()
