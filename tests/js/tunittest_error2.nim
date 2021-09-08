discard """
  exitcode: 1
  outputsub: '''
Unhandled exception: Cannot read properties of null (reading 'charCodeAt') [<foreign exception>]
[FAILED] Bad test
  '''
  matrix: "-d:nodejs"
  targets: "js"
  joinable: false
"""

# bug #16978
import unittest
test "Bad test":
  var x: cstring = nil
  let y = x[0]
