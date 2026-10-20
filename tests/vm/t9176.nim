discard """
  errormsg: "request to generate code for .compileTime proc: gorgeEx"
  line: 10
"""

# bug #9176: `gorgeEx` at runtime silently returned ("", 0)
const a = gorgeEx("echo hi")
doAssert a.exitCode == 0

proc f(s: string) = echo gorgeEx(s)
f("echo hi")
