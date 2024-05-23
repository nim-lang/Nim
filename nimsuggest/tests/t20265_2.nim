discard """
$nimsuggest --tester $file
>sug $1
sug;;skField;;a;;int;;*module_20265.nim;;2;;2;;"";;100;;None
sug;;skField;;b;;int;;*module_20265.nim;;3;;2;;"";;100;;None
"""
import module_20265
x.#[!]#
