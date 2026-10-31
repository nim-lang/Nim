discard """
output: '''
Seq works
seq works
'''
"""

# bug #19170

type Seq[U] = seq[U]

proc foo(s:typedesc[seq]) = echo "seq works"

proc foo(s:typedesc[Seq]) = echo "Seq works"

Seq.foo #works

seq.foo #compile error
