discard """
$nimsuggest --tester lib/pure/strutils.nim
>def lib/pure/strutils.nim:2300:6
def;;skTemplate;;system.doAssert;;proc (cond: bool, msg: string): typed;;*/lib/system.nim;;*;;9;;"";;100
"""

# Line 2300 in strutils.nim is doAssert and this is unlikely to change
# soon since there are a whole lot of doAsserts there.

