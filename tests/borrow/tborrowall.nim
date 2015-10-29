discard """
  output: "1000
magic string
magic some string
Magic magic string
10
some string
some some string
some magic string"
"""

# test the new borrow all feature:

type
  SomeString = string
  MagicString {.borrow.} = distinct string

proc magic(s: MagicString): MagicString = MagicString("Magic " & s.string)
proc magic(s: string): string = "magic " & s
proc magic(i: int): int = 999 + i

proc some(s: string): string = "some " & s
proc some(i: int): int = 9 + i

let aString = "string"
let someString = "some string"
let magicString = MagicString("magic string")

echo 1.magic
echo aString.magic
echo someString.magic
echo magicString.magic

echo 1.some
echo aString.some
echo someString.some
echo magicString.some
