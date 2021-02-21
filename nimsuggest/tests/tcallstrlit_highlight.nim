func foo(s: string) = discard

foo"string"#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skFunc;;1;;5;;3
highlight;;skType;;1;;12;;6
highlight;;skFunc;;3;;0;;3
"""
