discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''0'''
"""

proc other =
  raise newException(ValueError, "stuff happening")

proc indirectViaProcCall =
  var correct = 0
  for i in 1 .. 20:
    try:
      other()
    except:
      let x = getCurrentException()
      correct += ord(x of ValueError)
  doAssert correct == 20

proc direct =
  for i in 1 .. 20:
    try:
      raise newException(ValueError, "stuff happening")
    except ValueError:
      discard

let mem = getOccupiedMem()
indirectViaProcCall()
direct()
echo getOccupiedMem() - mem
