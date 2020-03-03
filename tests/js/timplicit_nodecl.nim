discard """
  output: '''22
22'''
"""

# test implicit nodecl
block:
  {. emit: "var importMe = 22;" .}
  var
    a {. importc: "importMe" .}: int
    importMe {. importc .}: int
  echo a
  echo importMe
