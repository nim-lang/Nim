discard """
$nimsuggest --tester $file
>sug $1
sug;;skField;;x;;int;;$file;;11;;4;;"";;100
sug;;skField;;y;;int;;$file;;11;;7;;"";;100
sug;;skProc;;tdot1.main;;proc (f: Foo);;$file;;13;;5;;"";;100
"""

type
  Foo = object
    x, y: int

proc main(f: Foo) =
  f.#[!]#
