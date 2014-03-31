discard """
  line: 10
  errormsg: "value of type 'bool' has to be discarded"
"""

proc p =
  var f: TFile
  echo "hi"
  
  open(f, "arg.txt")
  
p()
