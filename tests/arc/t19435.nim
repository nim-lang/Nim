discard """
  matrix: "--gc:arc"
"""

# bug #19435
{.experimental: "views".}

type
  Bar = object
    placeholder: int
  Foo = object
    placeholder: int
    c: seq[Bar] # remove this line to make things right

func children*(s: var seq[Foo]): openArray[Foo] =
  s.toOpenArray(0, s.len-1)

proc test =
  var foos = @[Foo(), Foo()]

  assert foos.children.len == 2
  var flag = true
  for a in foos.children:
    flag = false

  if flag:
    doAssert false

test()