template tmpa() = discard
macro tmpb() = discard
converter tmpc() = discard
tmp#[!]#

discard """
$nimsuggest --tester $file
>sug $1
sug;;skMacro;;tsug_template.tmpb;;macro (){.noSideEffect, gcsafe, locks: 0.};;$file;;2;;6;;"";;0;;Prefix
sug;;skConverter;;tsug_template.tmpc;;converter ();;$file;;3;;10;;"";;0;;Prefix
sug;;skTemplate;;tsug_template.tmpa;;template (): typed;;$file;;1;;9;;"";;0;;Prefix
"""
