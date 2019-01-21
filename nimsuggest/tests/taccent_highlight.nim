proc `$$$`#[!]#

discard """
disabled:true
$nimsuggest --tester $file
>highlight $1
highlight;;skProc;;1;;6;;3
"""
