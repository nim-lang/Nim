
discard """
cmd: "nim check --hints: off $file"
errormsg: "type mismatch: got <int literal(1), int literal(2), int literal(3)>"
nimout: '''
tdetailed_position.nim(23, 5) Error: type mismatch: got <int literal(1), int literal(2), int literal(3)>
but expected one of:
proc main(a, b, c: string)
  first type mismatch at position: 1
  required type for a: 'string'
  but expression '1' is of type: 'int literal(1)'

expression: main(1, 2, 3)
'''
"""

const
  myconst = "abcdefghijklmnopqrstuvwxyz"

proc main(a, b, c: string) {.deprecated: "use foo " & "instead " & myconst.} =
  return

main(1, 2, 3)
