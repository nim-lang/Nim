discard """
disabled:true
$nimsuggest --tester lib/pure/strutils.nim
>def lib/pure/strutils.nim:2529:6
def;;skTemplate;;system.doAssert;;proc (cond: bool, msg: string): typed;;*/lib/system.nim;;*;;9;;"same as `assert` but is always turned on and not affected by the\x0A``--assertions`` command line switch.";;100
"""

# Line 2529 in strutils.nim is doAssert and this is unlikely to change
# soon since there are a whole lot of doAsserts there.

