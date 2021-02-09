discard """
  output: '''
test1
'''
"""

import jsffi

type
  C = object
    props: int

var c: C

when compiles(c.props):
  echo "test1"

when compiles(d.props):
  echo "test2"
