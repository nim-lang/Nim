discard """
  output: '''
delete foo
delete foo
delete foo
'''
  matrix: "--mm:arc"
"""

type Foo = ref object of RootObj
  data: int
proc delete(self: Foo)
proc newFoo: Foo =
  let x = 12
  discard x
  new(result, delete)
  result.data = x
proc delete(self: Foo) =
  doAssert self.data == 12
  echo("delete foo")

if isMainModule:
  proc test() =
    let x1 = newFoo()
    let x2 = newFoo()
    discard x1
    discard x2
    var x3: Foo
    new(x3, delete)
    x3.data = 12
    discard x3
  test()