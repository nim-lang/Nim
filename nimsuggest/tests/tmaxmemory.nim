let foo = 30
let bar = foo + fo#[!]#o + foo

discard """
$nimsuggest --v3 --tester --maxMemory:4000 $file
>def $1
def;;skLet;;tmaxmemory.foo;;int;;$file;;1;;4;;"";;100
"""
