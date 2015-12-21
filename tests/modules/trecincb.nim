discard """
  line: 8
  errormsg: '''recursive dependency: 'trecincb.nim'
'''
"""
# Test recursive includes

include trecincb

echo "trecinb"
