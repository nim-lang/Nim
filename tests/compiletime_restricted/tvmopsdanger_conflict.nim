discard """
  cmd: '''nim c --compileTime:restricted --experimental:vmopsDanger --hints:off $file'''
  errormsg: "--experimental:vmopsDanger cannot be combined with --compileTime:restricted"
  file: "command line"
"""

# R6: vmopsDanger enables `execCmdEx` at compile time, which bypasses the
# staticExec whitelist.
