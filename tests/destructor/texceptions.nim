discard """
  cmd: '''nim c --gc:arc $file'''
  output: '''0'''
"""

proc other =
  raise newException(ValueError, "stuff happening")

proc indirectViaProcCall =
  for i in 1 .. 20:
    try:
      other()
    except:
      discard

proc direct =
  for i in 1 .. 20:
    try:
      raise newException(ValueError, "stuff happening")
    except:
      discard

let mem = getOccupiedMem()
indirectViaProcCall()
direct()
echo getOccupiedMem() - mem
