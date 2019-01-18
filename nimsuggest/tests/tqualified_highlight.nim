import macros
system.once: system.echo()
macros.dumpTree#[!]#

discard """
disabled:true
$nimsuggest --tester $file
>highlight $1
highlight;;skModule;;1;;7;;6
highlight;;skTemplate;;2;;7;;4
highlight;;skTemplate;;2;;7;;4
highlight;;skProc;;2;;20;;4
highlight;;skMacro;;3;;7;;8
highlight;;skMacro;;3;;7;;8
highlight;;skMacro;;3;;7;;8
"""
