discard """
cmd: "nim doc --hints:off $file"
action: "compile"
nimout: ""
joinable: false
"""


import selectors

try:
  discard
except IOSelectorsException:
  discard
