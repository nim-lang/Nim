discard """
  output: '''@["", "", "", "", "", "", "", "meh"]'''
  exitcode: "0"
"""

when true:
  var ab: string
  ab &= "more"

  doAssert ab == "more"

  var x: seq[string]

  setLen(x, 7)

  x.add "meh"

  var s: string
  var z = "abc"
  var zz: string
  s &= "foo" & z & zz

  doAssert s == "fooabc"

  echo x

  # casting an empty string as sequence with shallow() should not segfault
  var s2: string
  shallow(s2)
  s2 &= "foo"
  doAssert s2 == "foo"

