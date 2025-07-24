discard """
  action: "run"
  output: "0 4"
"""

proc main =
  var s = ""
  s.setLen(4)
  echo s[0].ord, " ", s.len

main()
