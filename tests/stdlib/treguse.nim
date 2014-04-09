discard """
  file: "treguse.nim"
  output: "055this should be the casehugh"
"""
# Test the register usage of the virtual machine and
# the blocks in var statements

proc main(a, b: int) =
  var x = 0
  write(stdout, x)
  if x == 0:
    var y = 55
    write(stdout, y)
    write(stdout, "this should be the case")
    var input = "<no input>"
    if input == "Andreas":
      write(stdout, "wow")
    else:
      write(stdout, "hugh")
  else:
    var z = 66
    write(stdout, z) # "bug!")

main(45, 1000)
#OUT 055this should be the casehugh


