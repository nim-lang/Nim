# suggestions for type declarations

from system import string, int, bool

type
  super = int
  someType = bool

let str = "hello"

proc main() =
  let a: s#[!]#

# This output show seq, even though that's not imported. This is due to the
# entire symbol table, regardless of import visibility is currently being
# scanned. This is hardly ideal, but changing it with the current level of test
# coverage is unwise as it might break more than it fixes.

discard """
$nimsuggest --tester $file
>sug $1
sug;;skType;;tsug_typedecl.someType;;someType;;*nimsuggest/tests/tsug_typedecl.nim;;7;;2;;"";;100;;Prefix
sug;;skType;;tsug_typedecl.super;;super;;*nimsuggest/tests/tsug_typedecl.nim;;6;;2;;"";;100;;Prefix
sug;;skType;;system.string;;string;;*lib/system.nim;;*;;*;;*;;100;;Prefix
sug;;skType;;system.seq;;seq;;*lib/system.nim;;*;;*;;*;;100;;Prefix
"""