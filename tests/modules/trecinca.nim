discard """
  file: "trecincb.nim"
  # Note: file must be "trecinab.nim"
  line: 9
  errormsg: '''recursive dependency: 'trecincb.nim'
'''
"""
# Test recursive includes

include trecincb

echo "trecina"
