# Test basic editing. We replace the 'false' by 'true' to
# see whether then the z field is suggested.

const zField = 0i32

type
  Foo = object
    x, y: int
    when zField == 1i32:
      z: string

proc main(f: Foo) =
  f.#[!]#

# the tester supports the spec section at the bottom of the file and
# this way, the line numbers more often stay the same
discard """
$nimsuggest --tester --maxresults:3 $file
>sug $1
sug;;skField;;x;;int;;$file;;8;;4;;"";;100;;None
sug;;skField;;y;;int;;$file;;8;;7;;"";;100;;None
sug;;skProc;;tdot2.main;;proc (f: Foo);;$file;;12;;5;;"";;100;;None
!edit 0i32 1i32
>sug $1
sug;;skField;;x;;int;;$file;;8;;4;;"";;100;;None
sug;;skField;;y;;int;;$file;;8;;7;;"";;100;;None
sug;;skField;;z;;string;;$file;;10;;6;;"";;100;;None
"""
