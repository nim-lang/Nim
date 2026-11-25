discard """
  output: '''
@[1]
@[1]
@["a"]
@[1, 2]
'''
"""

# bug #25685: implicit `items`/`pairs` in a generic must see the overloads
# of the generic's module
import m25685

type Foo = object
iterator items(f: Foo): int =
  yield 1
  yield 2

echo bar()
echo impl(true)
echo keys(0)
echo iterAny(Foo())
