discard """
  targets: "c js"
"""

{.experimental: "views".}

type
  Foo = object
    id: openArray[char]

proc foo(): Foo =
  var source = "1245"
  result = Foo(id: source.toOpenArray(0, 1))

doAssert foo().id == @['1', '2']
