type Foo = object
  x, y: float

proc `[]`(foo: var Foo, i: int): var float =
  if i == 0:
    result = foo.x
  else:
    result = foo.y

var pt = Foo(x: 0.0, y: 0.0)
pt[0] += 1.0 # <-- fine
`[]`(pt, 0) = 1.0 # <-- fine
pt[0] = 1.0 # <-- does not compile

# curly:

proc `{}`(foo: var Foo, i: int): var float =
  if i == 0:
    result = foo.x
  else:
    result = foo.y

pt{0} += 1.0 # <-- fine
`{}`(pt, 0) = 1.0 # <-- fine
pt{0} = 1.0 # <-- does not compile
