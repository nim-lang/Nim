discard """
  exitcode: 1
  outputsub: '''
Unhandled exception: Cannot read property 'charCodeAt' of null [<foreign exception>]
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
