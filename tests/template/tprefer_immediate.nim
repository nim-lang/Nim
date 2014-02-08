discard """
  output: '''immediate'''
"""

# Test that immediate templates are preferred over non-immediate templates

template foo(a, b: expr) = echo "foo expr"

template foo(a, b: int) = echo "foo int"
template foo(a, b: float) = echo "foo float"
template foo(a, b: string) = echo "foo string"
template foo(a, b: expr) {.immediate.} = echo "immediate"
template foo(a, b: bool) = echo "foo bool"
template foo(a, b: char) = echo "foo char"

foo(undeclaredIdentifier, undeclaredIdentifier2)

