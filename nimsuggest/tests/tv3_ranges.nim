proc name(a: string): int =
  return 10
#[!]#
discard """
$nimsuggest --v3 --tester $file
>def $1
def	skModule	tv3		*/tv3.nim	1	0	""	100
"""
