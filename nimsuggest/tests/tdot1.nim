discard """
$nimsuggest --tester --maxresults:3 $file
>sug $1
sug;;skField;;x;;int;;$file;;11;;4;;"";;100;;None
sug;;skField;;y;;int;;$file;;11;;7;;"";;100;;None
sug;;skProc;;tdot1.main;;proc (f: Foo);;$file;;13;;5;;"";;100;;None
"""

type
  Foo = object
    x, y: int

proc main(f: Foo) =
  if f.#[!]#:
