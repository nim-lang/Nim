discard """
  nimout: "abc xyz bb"
"""

# bug #2473
type
  Test = tuple[a,b: string]

static:
  var s:seq[Test] = @[(a:"a", b:"b")]
  s[0] = (a:"aa", b:"bb")

  var x: Test
  x.a = "abc"
  x.b = "xyz"
  echo x.a, " ", x.b, " ", s[0].b
