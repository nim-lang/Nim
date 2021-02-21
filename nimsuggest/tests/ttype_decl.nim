discard """
$nimsuggest --tester --maxresults:3 $file
>sug $1
sug;;skType;;ttype_decl.Other;;Other;;$file;;10;;2;;"";;100;;None
sug;;skType;;system.int;;int;;*/lib/system/basic_types.nim;;2;;2;;"";;100;;None
sug;;skType;;system.string;;string;;*/lib/system.nim;;34;;2;;"";;100;;None
"""
import strutils
type
  Other = object ## My other object.
  Foo = #[!]#
  OldOne {.deprecated.} = object
    x: int

proc main(f: Foo) =

# XXX why no doc comments?
