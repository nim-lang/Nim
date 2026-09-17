discard """
  cmd: "nim c -r --gc:arc --exceptions:goto --panics:off $file"
  output: '''
In test
destroy
in defect
'''
"""

type MyObject = object

proc `=destroy`(a: var MyObject) =
  debugEcho "destroy"

proc test(): int8 =
  debugEcho "In test"
  raiseAssert "a defect"

proc noex() =
  try:
    let x = block:
      var v = MyObject()
      test()
    echo x
  except AssertionDefect:
    debugEcho "in defect"

noex()
