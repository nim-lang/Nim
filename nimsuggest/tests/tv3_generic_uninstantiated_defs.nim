type
  A = object
  B = object

proc multiDefOp(x: A) = discard
proc multiDefOp(x: B) = discard

# never instantiated: no concrete instantiation can record the resolved
# overload, so the definition query must offer every candidate instead.
proc wrapper[T](x: T) =
  mul#[!]#tiDefOp(x)

discard """
$nimsuggest --v3 --tester $file
>def $1
def;;skProc;;tv3_generic_uninstantiated_defs.multiDefOp;;proc (x: B){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;6;;5;;"";;100
def;;skProc;;tv3_generic_uninstantiated_defs.multiDefOp;;proc (x: A){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;5;;5;;"";;100
"""
