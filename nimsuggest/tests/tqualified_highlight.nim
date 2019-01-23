system.echo#[!]#

discard """
disabled:true
$nimsuggest --tester $file
>highlight $1
highlight;;skProc;;1;;7;;4
highlight;;skProc;;1;;7;;4
"""
