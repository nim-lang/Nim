discard """
output: '''
abc
xyz
B.foo
'''
"""

# bug #1595, #1612

import mexport2a

proc main() =
  printAbc()
  printXyz()

main()
foo(3)
