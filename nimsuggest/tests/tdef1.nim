discard """
$nimsuggest --tester $file
>def $1
def;;skProc;;tdef1.hello;;proc (): string{.noSideEffect, gcsafe, locks: 0.};;$file;;9;;5;;"Return hello";;100
>def $1
def;;skProc;;tdef1.hello;;proc (): string{.noSideEffect, gcsafe, locks: 0.};;$file;;9;;5;;"Return hello";;100
"""

proc hello(): string =
  ## Return hello
  "Hello"

hel#[!]#lo()

# v uncompleted id for sug (13,2)
he
