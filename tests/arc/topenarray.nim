discard """
  input: "hi"
  output: '''
hi
Nim
'''
  matrix: "--gc:arc -d:useMalloc; --gc:arc"
"""
block: # bug 18627
  proc setPosition(params: openArray[string]) =
    for i in params.toOpenArray(0, params.len - 1):
      echo i

  proc uciLoop() =
    let params = @[readLine(stdin)]
    setPosition(params)

  uciLoop()

  proc uciLoop2() =
    let params = @["Nim"]
    for i in params.toOpenArray(0, params.len - 1):
      echo i
  uciLoop2()
