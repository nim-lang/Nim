type
  A = object
  B = object

proc handle(x: A) = discard
proc handle(x: B) = discard

proc wrapper[T](x: T) =
  han#[!]#dle(x)

wrapper(A())
wrapper(B())

discard """
$nimsuggest --v3 --tester $file
>def $1
def;;skProc;;tv3_generic_multiple_defs.handle;;proc (x: B){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;6;;5;;"";;100
def;;skProc;;tv3_generic_multiple_defs.handle;;proc (x: A){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;5;;5;;"";;100
"""
