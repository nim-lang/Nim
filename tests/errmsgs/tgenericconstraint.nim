discard """
  errormsg: "cannot instantiate B"
  line: 14
  nimout: '''
got: <typedesc[int]>
but expected: <T: string or float>
'''
"""

type
  B[T: string|float] = object
    child: ref B[T]

var b: B[int]

