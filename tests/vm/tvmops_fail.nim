discard """
  errormsg: '''gorge failed: (exitCode: 127, cmd: "D20190116T211842", input: "")'''
"""

# issue #1994

#[
This doesn't work as VM error isn't catchable
block:
  static:
    doAssertRaises(AssertionError):
]#

const nonexistant = "D20190116T211842"
const a = gorge(nonexistant)
