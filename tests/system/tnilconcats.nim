discard """
  output: '''@[nil, nil, nil, nil, nil, nil, nil, "meh"]'''
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
