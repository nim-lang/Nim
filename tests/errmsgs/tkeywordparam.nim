discard """
cmd: "nim check $file"
errormsg: "'type' is a keyword and cannot be used as a parameter name"
nimout: '''
tkeywordparam.nim(1, 13) Error: 'type' is a keyword and cannot be used as a parameter name
'''
"""

proc myproc(type: int) =
  echo type
