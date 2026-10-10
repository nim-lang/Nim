proc `%%%`(a: int) = discard
proc `cast`() = discard
tsug_accquote.#[!]#

discard """
$nimsuggest --tester $file
>sug $1
sug;;skProc;;tsug_accquote.`%%%`;;proc (a: int){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;1;;5;;"";;100;;None
sug;;skProc;;tsug_accquote.`cast`;;proc (){.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;2;;5;;"";;100;;None
"""
