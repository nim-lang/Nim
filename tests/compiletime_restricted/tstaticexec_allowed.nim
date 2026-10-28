discard """
  cmd: '''nim c --compileTime:restricted "--staticExecWhitelist:echo hi" -r --hints:off $file'''
  output: "hi"
  disabled: "windows"
"""

# R1: a command line that is on the whitelist runs.
const greeting = staticExec("echo hi")
echo greeting
