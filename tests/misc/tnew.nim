discard """
outputsub: '''
Simple tree node allocation worked!
Simple cycle allocation worked!
'''
joinable: false
"""

# Test the implementation of the new operator
# and the code generation for gc walkers
# (and the garbage collector):

type
  PNode = ref TNode
  TNode = object
    data: int
    str: string
    le, ri: PNode

  TStressTest = ref array[0..45, array[1..45, TNode]]

proc finalizer(n: PNode) =
  write(stdout, n.data)
  write(stdout, " is now freed\n")

proc newNode(data: int, le, ri: PNode): PNode =
  new(result, finalizer)
  result.le = le
  result.ri = ri
  result.data = data

# now loop and build a tree
proc main() =
  var
    i = 0
    p: TStressTest
  while i < 1000:
    var n: PNode

    n = newNode(i, nil, newNode(i + 10000, nil, nil))
    inc(i)
  new(p)

  write(stdout, "Simple tree node allocation worked!\n")
  i = 0
  while i < 1000:
    var m = newNode(i + 20000, nil, nil)
    var k = newNode(i + 30000, nil, nil)
    m.le = m
    m.ri = k
    k.le = m
    k.ri = k
    inc(i)

  write(stdout, "Simple cycle allocation worked!\n")

main()
