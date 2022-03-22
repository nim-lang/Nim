discard """
  errormsg: "'copy' can have side effects"
  nimout: '''an object reachable from 'y' is potentially mutated
tfuncs_cannot_mutate2.nim(15, 7) the mutation is here
tfuncs_cannot_mutate2.nim(13, 10) is the statement that connected the mutation to the parameter
'''
"""

{.experimental: "strictFuncs".}

func copy[T](x: var openArray[T]; y: openArray[T]) =
  for i in 0..high(x):
    x[i] = y[i]

  x[0].a = nil

type
  R = ref object
    a, b: R
    data: string

proc main =
  var a, b: array[3, R]
  b = [R(data: "a"), R(data: "b"), R(data: "c")]
  copy a, b

main()
