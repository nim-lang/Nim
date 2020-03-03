discard """
  output: '''@["a", "c"]'''
"""

# bug #3230

import sequtils

const
  test_strings = ["a", "b", "c"]

proc is_doc(x: string): bool = x == "b"

let
  tests = @test_strings.filter_it(not it.is_doc)
echo tests
