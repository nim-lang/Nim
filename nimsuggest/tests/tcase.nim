
type
  MyEnum = enum
    nkIf, nkElse, nkElif

proc test(a: MyEnum) =
  case a
  of nkElse: discard
  of #[!]#

discard """
$nimsuggest --tester $file
>sug $1
sug;;skEnumField;;nkElse;;MyEnum;;$file;;4;;10;;"";;100;;None
sug;;skEnumField;;nkElif;;MyEnum;;$file;;4;;18;;"";;100;;None
sug;;skEnumField;;nkIf;;MyEnum;;$file;;4;;4;;"";;100;;None
"""
