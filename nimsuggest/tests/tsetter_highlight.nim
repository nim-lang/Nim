proc `a=`(a, b: int) = discard
10.a = 1000#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skProc;;1;;6;;2
highlight;;skType;;1;;16;;3
highlight;;skProc;;2;;5;;1
"""
