discard """
  output: "delete foo"
  matrix: "--mm:arc"
"""

type Foo = ref object of RootObj
proc delete(self: Foo) 
proc newFoo: Foo = new(result, delete)
proc delete(self: Foo) = echo("delete Foo")

if isMainModule:
  proc test() = discard newFoo()
  test()