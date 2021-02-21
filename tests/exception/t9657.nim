discard """
  action: run
  exitcode: 1
  targets: "c cpp"
  disabled: "openbsd"
  disabled: "netbsd"
"""

close stdmsg
const m = "exception!"
# see #10343 for details on this test
discard writeBuffer(stdmsg, cstring(m), m.len)
