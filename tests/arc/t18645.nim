discard """
  matrix: "--gc:arc; --gc:refc"
  output: '''
1
2
3
'''
"""

proc bitTypeIdUnion() =
  var bitId {.global.} = block:
    0
  inc bitId
  echo bitId

bitTypeIdUnion()
bitTypeIdUnion()
bitTypeIdUnion()
