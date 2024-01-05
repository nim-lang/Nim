discard """
  output: '''
A: abc
B: 123
4
'''
"""
# Module C
import mambsym3, mambsym4

foo("abc") # A: abc
foo(123) # B: 123

doAssert not compiles(write(stdout, x)) # error: x is ambiguous
write(stdout, mambsym3.x) # no error: qualifier used

proc bar(a: int): int = a + 1
doAssert bar(x) == x + 1 # no error: only A.x of type int matches

var x = 4
write(stdout, x) # not ambiguous: uses the module C's x
write(stdout, '\n')
