discard """
  output: '''10'''
"""

# bug #940

type
  Foo* = ref object
    b*: int

proc new*(this: var Foo) =
  assert this != nil
  this.b = 10

proc new*(T: typedesc[Foo]): Foo =
  system.new(result)
  twrongopensymchoice.new(result)

proc main =
  var f = Foo.new()
  echo f.b

when true:
  main()
