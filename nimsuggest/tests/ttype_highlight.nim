type
  TypeA = int
  TypeB* = int
  TypeC {.unchecked.} = array[1, int]
  TypeD[T] = T
  TypeE* {.unchecked.} = array[0, int]#[!]#

discard """
$nimsuggest --tester $file
>highlight $1
highlight;;skType;;2;;2;;5
highlight;;skType;;3;;2;;5
highlight;;skType;;4;;2;;5
highlight;;skType;;5;;2;;5
highlight;;skType;;6;;2;;5
highlight;;skType;;2;;10;;3
highlight;;skType;;3;;11;;3
highlight;;skType;;4;;24;;5
highlight;;skType;;4;;33;;3
highlight;;skType;;5;;13;;1
highlight;;skType;;6;;25;;5
highlight;;skType;;6;;34;;3
highlight;;skType;;2;;10;;3
highlight;;skType;;3;;11;;3
highlight;;skType;;4;;33;;3
highlight;;skType;;6;;34;;3
"""
