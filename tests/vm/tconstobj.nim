discard """
  output: '''(name: hello)'''
"""

# bug #2774

type Foo = object
  name: string

const fooArray = [
  Foo(name: "hello")
]

echo fooArray[0]
