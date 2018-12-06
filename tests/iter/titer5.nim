discard """
  output: "abcxyz"
"""
# Test method call syntax for iterators:
import strutils

const lines = """abc  xyz"""

for x in lines.split():
  stdout.write(x)

#OUT abcxyz
stdout.write "\n"
