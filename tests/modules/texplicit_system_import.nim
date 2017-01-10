##.
import system except `+`
discard """
  errormsg: "undeclared identifier: '+'"
  line: 9
"""
# Testament requires that the initial """ occurs before the 40th byte
# in the file. No kidding...
echo 4+5
