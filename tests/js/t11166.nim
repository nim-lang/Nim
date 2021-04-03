discard """
  output: '''
test1
test2
'''
"""

import jsffi

type
  C = object
    props: int

var c: C

when compiles(c.props):
  echo "test1"

when not compiles(d.props):
  echo "test2"
