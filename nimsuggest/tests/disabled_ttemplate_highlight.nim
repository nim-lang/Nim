doAssert true#[!]#

discard """
$nimsuggest --tester $1
>highlight $1
highlight;;skTemplate;;1;;0;;8
highlight;;skTemplate;;1;;0;;8
highlight;;skEnumField;;1;;9;;4
"""
