discard """
  output: '''
destroyed: false
destroyed: false
closed
destroying variable
'''
  cmd: "nim c --gc:arc $file"
"""

# bug #13691
type Variable = ref object
  value: int

proc `=destroy`(self: var typeof(Variable()[])) =
  echo "destroying variable"

proc newVariable(value: int): Variable =
  result = Variable()
  result.value = value

proc test(count: int) =
  var v {.global.} = newVariable(10)

  var count = count - 1
  if count == 0: return

  test(count)
  echo "destroyed: ", v.isNil

test(3)


#------------------------------------------------------------------------------
# issue #13810

import streams

type
  A = ref AObj
  AObj = object of RootObj
    io: Stream
  B = ref object of A
    x: int

proc `=destroy`(x: var AObj) =
  close(x.io)
  echo "closed"
  
var x = B(io: newStringStream("thestream"))
