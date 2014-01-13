discard """
  line: 10
  errormsg: "value returned by statement has to be discarded"
"""

proc p =
  var f: TFile
  echo "hi"
  
  open(f, "arg.txt")
  
p()
