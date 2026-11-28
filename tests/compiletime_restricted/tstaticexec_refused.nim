discard """
  cmd: '''nim c --compileTime:restricted "--staticExecWhitelist:echo hi" --hints:off $file'''
  errormsg: "command refused by --compileTime:restricted, it is not in --staticExecWhitelist: 'echo hi there'"
  line: 9
"""

# R1: the whitelist matches the whole command line, so a longer command line
# that starts with an allowed one is refused.
const greeting = staticExec("echo hi there")
