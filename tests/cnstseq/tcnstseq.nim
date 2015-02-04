discard """
  file: "tcnstseq.nim"
  output: "AngelikaAnneAnnaAnkaAnja"
"""
# Test the new implicit conversion from sequences to arrays in a constant
# context.

import strutils

const
  myWords = "Angelika Anne Anna Anka Anja".split()

for x in items(myWords):
  write(stdout, x) #OUT AngelikaAnneAnnaAnkaAnja



