discard """
output: '''
Length correct
Correct
Correct
Correct
Correct
Correct
Correct
Correct
Correct
'''
"""

type
  TIdObj* = object of RootObj
    id*: int                  # unique id; use this for comparisons and not the pointers

  PIdObj* = ref TIdObj
  PIdent* = ref TIdent
  TIdent*{.acyclic.} = object
    s*: string

proc myNewString(L: int): string {.inline.} =
  result = newString(L)
  if result.len == L: echo("Length correct")
  else: echo("bug")
  for i in 0..L-1:
    if result[i] == '\0':
      echo("Correct")
    else:
      echo("Wrong")

var s = myNewString(8)
