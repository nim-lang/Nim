discard """
disabled:true
$nimsuggest --tester --maxresults:2 $file
>sug $1
sug;;skProc;;tdot4.main;;proc (inp: string): string;;$file;;10;;5;;"";;100;;None
sug;;skProc;;strutils.replace;;proc (s: string, sub: string, by: string): string{.noSideEffect, gcsafe, locks: 0.};;$lib/pure/strutils.nim;;1506;;5;;"Replaces `sub` in `s` by the string `by`.";;100;;None
"""

import strutils

proc main(inp: string): string =
  # use replace here and see if it occurs in the result, it should gain
  # priority:
  result = inp.replace(" ", "a").replace("b", "c")


echo "string literal here".#[!]#
