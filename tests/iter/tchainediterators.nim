discard """
  output: '''16
32
48
64
128
192
'''
  disabled: "true"
"""

# This all relies on non-documented and questionable features.

iterator gaz(it: iterator{.inline.}): type(it) =
  for x in it:
    yield x*2

iterator baz(it: iterator{.inline.}): auto =
  for x in gaz(it):
    yield x*2

type T1 = auto

iterator bar(it: iterator: T1{.inline.}): T1 =
  for x in baz(it):
    yield x*2

iterator foo[T](x: iterator: T{.inline.}): T =
  for e in bar(x):
    yield e*2

var s = @[1, 2, 3]

# pass an iterator several levels deep:
for x in s.items.foo:
  echo x

# use some complex iterator as an input for another one:
for x in s.items.baz.foo:
  echo x

