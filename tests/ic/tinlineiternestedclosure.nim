discard """
  description: "IC: a nested closure in another module's inline iterator"
  output: '''1'''
"""

# Regression test: under `nim ic`, an inline iterator from another module whose
# body contains a nested closure capturing a local failed in the backend with
# `internal error: expr: var not init x_<id>`.


import minlineiternestedclosure

proc run() =
  for y in it():
    echo y

run()
