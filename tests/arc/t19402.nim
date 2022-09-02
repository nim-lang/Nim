discard """
  output: '''
delete foo
delete foo
delete foo
'''
  matrix: "--mm:arc"
"""


type Foo = ref object of RootObj
proc delete(self: Foo)
proc newFoo: Foo =
  let x = 12
  discard x
  new(result, delete)
proc delete(self: Foo) = echo("delete Foo")

if isMainModule:
  proc test() =
    let x1 = newFoo()
    let x2 = newFoo()
    discard x1
    discard x2
    var x3: Foo
    new(x3, delete)
    discard x3
  test()