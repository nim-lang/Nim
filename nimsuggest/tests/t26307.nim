# bug #26307: `def` on modules listed in `./[a, b]`
import ./[mo#[!]#dule_26307,
  module_#[!]#20265]

discard """
$nimsuggest --tester --v4 $file
>def $1
def;;skModule;;module_26307;;;;*module_26307.nim;;1;;0;;""
>def $2
def;;skModule;;module_20265;;;;*module_20265.nim;;1;;0;;""
"""
