proc a: int = 0
e_c_h_o#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skProc;;1;;5;;1
highlight;;skType;;1;;8;;3
highlight;;skResult;;1;;0;;0
highlight;;skProc;;2;;0;;7
"""
