discard """
  output: '''
hmm
100
hmm
100
'''
"""

# #16800

type A = object
  b: int
var t = A(b: 100)
block:
  proc getValues: lent int =
    echo "hmm"
    result = t.b
  echo getValues()
block:
  proc getValues: lent int =
    echo "hmm"
    t.b
  echo getValues()

when false: # still an issue, #16908
  template main =
    iterator fn[T](a:T): lent T = yield a
    let a = @[10]
    for b in fn(a): echo b

  static: main()
  main()
