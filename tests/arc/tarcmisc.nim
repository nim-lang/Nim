discard """
  output: '''
destroyed: false
destroyed: false
destroying variable'''
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
