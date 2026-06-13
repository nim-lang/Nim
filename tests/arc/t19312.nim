discard """
  matrix: "--mm:orc"
  output: '''(val: 1)
(val: 1)'''
"""
# Issue #19312: copied ref object is converted to nil if not used in declaration module under ARC/ORC
# https://github.com/nim-lang/Nim/issues/19312

type
  Wrapper* = object
    val: int
  RefWrapper* = ref Wrapper

let
  a* = RefWrapper(val: 1)
  b* = a

echo b[]
echo a[]
