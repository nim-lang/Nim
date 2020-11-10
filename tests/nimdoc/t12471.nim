discard """
  cmd: "nim doc --hints:off $file"
  action: "compile"
"""


import selectors

try:
  discard
except IOSelectorsException:
  discard

runnableExamples:
  discard
