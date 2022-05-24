# Test def with type definition in separate file

discard """
$nimsuggest --v3 --tester /home/yyoncho/Sources/nim/Nim/nimsuggest/tests/fixtures/nimble.nim
>use /home/yyoncho/Sources/nim/Nim/nimsuggest/tests/fixtures/packageinfotypes.nim:3:4
def	skField	packageinfotypes.PackageInfo.isMinimal	string	/home/yyoncho/Sources/nim/Nim/nimsuggest/tests/fixtures/packageinfotypes.nim	3	4	""	100
use	skField	packageinfotypes.PackageInfo.isMinimal	string	/home/yyoncho/Sources/nim/Nim/nimsuggest/tests/fixtures/nimble.nim	5	21	""	100
use	skField	packageinfotypes.PackageInfo.isMinimal	string	/home/yyoncho/Sources/nim/Nim/nimsuggest/tests/fixtures/nimble.nim	6	24	""	100
"""
