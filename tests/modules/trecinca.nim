discard """
  file: "tests/modules/trecincb.nim"
  # Note: file must be "trecinab.nim"
  line: 8
  errormsg: '''recursive dependency: 'trecincb.nim'
'''
"""
# Test recursive includes

include trecincb

echo "trecina"
