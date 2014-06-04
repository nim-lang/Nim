discard """
msg: '''a
s
d
f'''
"""

type
  Foo = object
    s: char

iterator test2(f: string): Foo =
  for i in f:
    yield Foo(s: i)

macro test(): stmt =
  for i in test2("asdf"):
    echo i.s

test()
