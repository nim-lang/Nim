import fixtures/mdep#[!]#
discard """
$nimsuggest --tester --v4 $file
>sug $1
sug;;skModule;;mdep_v1;;;;mdep_v1;;1;;0;;"";;100;;None
sug;;skModule;;mdep_v2;;;;mdep_v2;;1;;0;;"";;100;;None
"""
