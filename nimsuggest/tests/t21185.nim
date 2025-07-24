
# Reduced case of 21185. Issue was first parameter being static
proc foo(x: static[int]) = discard

type
  Person = object
    name: string
    age: int

let p = Person()
p.#[!]#

discard """
$nimsuggest --tester --v3 --maxresults:2 $file
>sug $1
sug;;skField;;age;;int;;$file;;8;;4;;"";;100;;None
sug;;skField;;name;;string;;$file;;7;;4;;"";;100;;None
"""
