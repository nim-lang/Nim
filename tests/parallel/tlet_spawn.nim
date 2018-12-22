discard """
output: '''
done999 999
'''
"""

import threadpool

proc foo(): int = 999

# test that the disjoint checker deals with 'a = spawn f(); g = spawn f()':

proc main =
  parallel:
    let f = spawn foo()
    let b = spawn foo()
  echo "done", f, " ", b

main()
