discard """
  output: '''done'''
"""
# Issue #14913: Compiler crash when using a default parameter value for a parameter whose type is a concept
# https://github.com/nim-lang/Nim/issues/14913

type
  State = object
  MoreState = object
  StringRecord = concept x, type T
    for k, v in fieldPairs(x):
      k is string
      v is string
  StateStrings = object
    a, b: string

proc combine(a: State, b: MoreState): StateStrings = discard

proc whoops[T: StringRecord](a: State, b: MoreState, c: T = a.combine(b)) =
  discard

whoops(State(), MoreState())
echo "done"
