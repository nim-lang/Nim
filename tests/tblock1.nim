# check for forward label and
# for failure when label is not declared

import
  io

proc main =
  block endLess:
    break endLess
    write(stdout, "Muaahh!\N")


  break ha #ERROR

main()
