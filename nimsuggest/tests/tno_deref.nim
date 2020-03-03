
var x: ptr int

proc foo(y: ptr int) =
    discard

x.#[!]#

discard """
$nimsuggest --tester $file
>sug $1
sug;;skProc;;tno_deref.foo;;proc (y: ptr int)*;;$file;;4;;5;;"";;100;;None
*
"""
