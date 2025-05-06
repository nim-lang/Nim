import fixtures/mcl#[!]#
import fixtures/[mstrutils, mfak#[!]#]
discard """
$nimsuggest --tester --v4 --maxresults:1 $file
>sug $1
sug;;skModule;;mclass_macro;;;;mclass_macro;;1;;0;;"";;100;;None
>sug $2
sug;;skModule;;mfakeassert;;;;mfakeassert;;2;;0;;"";;100;;None
"""
