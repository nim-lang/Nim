discard """
disabled:true
$nimsuggest --tester --maxresults:3 $file
>sug $1
sug;;skType;;ttype_decl.Other;;Other;;$file;;10;;2;;"";;0;;None
sug;;skType;;system.int;;int;;$lib/system.nim;;25;;2;;"";;0;;None
sug;;skType;;system.string;;string;;$lib/system.nim;;48;;2;;"";;0;;None
"""
import strutils
type
  Other = object ## My other object.
  Foo = #[!]#

proc main(f: Foo) =

# XXX why no doc comments?
