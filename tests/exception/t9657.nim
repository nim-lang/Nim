discard """
  action: run
  exitcode: 1
  target: "c"
  disabled: "openbsd"
  disabled: "netbsd"
"""
# todo: remove `target: "c"` workaround once #10343 is properly fixed
close stdmsg
const m = "exception!"
discard writeBuffer(stdmsg, cstring(m), m.len)
