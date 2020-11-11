import json

%*{}#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skModule;;1;;7;;4
highlight;;skMacro;;3;;0;;2
highlight;;skMacro;;3;;0;;2
"""
