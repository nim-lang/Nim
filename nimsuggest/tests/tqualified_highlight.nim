system.echo#[!]#
system.once
system.`$` 1

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skProc;;1;;7;;4
highlight;;skProc;;1;;7;;4
highlight;;skTemplate;;2;;7;;4
highlight;;skTemplate;;2;;7;;4
highlight;;skTemplate;;2;;7;;4
highlight;;skFunc;;3;;8;;1
"""
