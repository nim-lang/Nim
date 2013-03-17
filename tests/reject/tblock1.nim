discard """
  file: "tblock1.nim"
  line: 14
  errormsg: "undeclared identifier: \'ha\'"
"""
# check for forward label and
# for failure when label is not declared

proc main =
  block endLess:
    write(stdout, "Muaahh!\N")
    break endLess

  break ha #ERROR

main()


