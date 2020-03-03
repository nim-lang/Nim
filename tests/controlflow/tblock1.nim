discard """
  errormsg: "undeclared identifier: \'ha\'"
  file: "tblock1.nim"
  line: 14
"""
# check for forward label and
# for failure when label is not declared

proc main =
  block endLess:
    write(stdout, "Muaahh!\N")
    break endLess

  break ha #ERROR

main()
