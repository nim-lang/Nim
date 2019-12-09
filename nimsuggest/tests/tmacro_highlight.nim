macro a(b: string): untyped = discard

a "string"#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skMacro;;1;;6;;1
highlight;;skType;;1;;11;;6
highlight;;skType;;1;;20;;7
highlight;;skMacro;;3;;0;;1
highlight;;skMacro;;3;;0;;1
"""
