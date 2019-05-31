discard """
  action: run
  exitcode: 1
  target: "c"
"""
# todo: remove `target: "c"` workaround once #10343 is properly fixed
close stdmsg
writeLine stdmsg, "exception!"
