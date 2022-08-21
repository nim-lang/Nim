discard """
$nimsuggest --tester $file
>def $1
def;;skProc;;tdef_forward.hello;;proc (): string;;$file;;8;;5;;"";;100
def;;skProc;;tdef_forward.hello;;proc (): string;;$file;;12;;5;;"";;100
"""

proc hello(): string

hel#[!]#lo()

proc hello(): string =
  "Hello"
