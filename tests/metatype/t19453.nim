discard """
output: '''
[1, 2, 3]
[1, 2, 3]
'''
"""

# bug #19453

{.experimental: "views".}

let data: seq[byte] = @[1.byte, 2, 3]

iterator items[T]: T =
  yield data.toOpenArray(data.low, data.high)

iterator items(T: typedesc): T =
  yield data.toOpenArray(data.low, data.high)

proc test =
  for item in items(openArray[byte]): # this works
    echo item

  for item in items[openArray[byte]](): # Error: type mismatch: got <typedesc[openArray[byte]]>
    echo item

test()
