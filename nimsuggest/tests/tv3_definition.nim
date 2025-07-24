
let foo = 30
let bar = foo + fo#[!]#o + foo

discard """
$nimsuggest --v3 --tester $file
>def $1
def	skLet	tv3_definition.foo	int	$file	2	4	""	100
"""
