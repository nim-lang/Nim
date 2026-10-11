discard """
  targets: "c js"
  output: '''
Foo
Foo
'''
"""

# bug #10506: a concept matched by a subtype passed to a base type param
type
  Foo = object of RootObj
  Bar = object of Foo

  FooOrBar = concept s, type T
    s is T
    f(s) is string

  HasF = concept s
    f(s) is string

proc f(f: Foo): string = "Foo"

proc conceptf(f: FooOrBar): string =
  f(f)

proc conceptg(f: HasF): string =
  f(f)

let bar = Bar()
echo conceptf(bar)
echo conceptg(bar)
