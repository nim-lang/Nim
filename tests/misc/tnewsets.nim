discard """
  file: "tnewsets.nim"
"""
# new test for sets:

const elem = ' '

var s: set[char] = {elem}
doAssert(elem in s and 'a' not_in s and 'c' not_in s )
