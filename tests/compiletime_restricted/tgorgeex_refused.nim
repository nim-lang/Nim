discard """
  cmd: '''nim c --compileTime:restricted --hints:off $file'''
  errormsg: "command refused by --compileTime:restricted, it is not in --staticExecWhitelist: 'echo hi'"
  line: 8
"""

# R1: an empty whitelist runs nothing; `gorgeEx` takes the same check.
const res = gorgeEx("echo hi")
