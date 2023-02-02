discard """
  cmd: "nim check --hints:off $file"
  errormsg: ""
  nimout: '''
t19678.nim(13, 13) Error: range of string is invalid



'''
"""

case "5":
  of "0" .. "9":
    discard
  else:
    discard

