import std/assertions
doAssert true#[!]#

discard """
$nimsuggest --tester $1
>highlight $1
highlight;;skTemplate;;2;;0;;8
highlight;;skTemplate;;2;;0;;8
highlight;;skEnumField;;2;;9;;4
"""
