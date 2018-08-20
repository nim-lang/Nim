discard """
  output: '''true
false
true
false
false
true
'''
"""

type Foo = int | float

proc bar(t1, t2: typedesc): bool =
  echo (t1 is t2)
  (t2 is t1)

proc bar[T](x: T, t2: typedesc): bool =
  echo (T is t2)
  (t2 is T)

echo bar(int, Foo)
echo bar(4, Foo)
echo bar(any, Foo)
