discard """
  output: '''
@["monday"]
'''
"""

# bug #13595: method call syntax for a routine taking an iterable
import tables, sequtils
var tab = initTable[string, int]()
tab["monday"] = 1
echo tab.keys.toSeq
