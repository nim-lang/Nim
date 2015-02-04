discard """
  output: "Hello World"
"""

# Test incremental type information

type
  TNode = object {.pure.}
    le, ri: ref TNode
    data: string

proc newNode(data: string): ref TNode =
  new(result)
  result.data = data

echo newNode("Hello World").data

