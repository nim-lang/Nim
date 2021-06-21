let foo = "string"
var bar = "string"
bar#[!]#.add foo
bar.add foo#[!]#

discard """
$nimsuggest --tester $file
>con $1
con;;skVar;;tcon_variable.bar;;string;;$file;;2;;4;;"";;100
>con $2
con;;skLet;;tcon_variable.foo;;string;;$file;;1;;4;;"";;100
"""
