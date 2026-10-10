# tests v3

proc test(a: string, b:string) = discard
proc test(a: int) = discard

test(#[!]#

discard """
$nimsuggest --v3 --tester $file
>con $1
con;;skProc;;tv3_con.test;;proc (a: string, b: string){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;3;;5;;"";;100
con;;skProc;;tv3_con.test;;proc (a: int){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;4;;5;;"";;100
"""
