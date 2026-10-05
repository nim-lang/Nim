discard """
  action: "reject"
  errormsg: "invalid type: 'iterator (a: int, b: int, step: Positive): int{.inline, noSideEffect, gcsafe.}' for const"
  line: 9
"""
# Issue #16956: Error: not unused depending on unrelated code changes
# https://github.com/nim-lang/Nim/issues/16956

const f2 = case true
  of true:  countup[int]
  of false: countdown[int]
