type
  O = object
    a*: int#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skType;;2;;2;;1
highlight;;skType;;3;;8;;3
highlight;;skField;;3;;4;;1
"""
