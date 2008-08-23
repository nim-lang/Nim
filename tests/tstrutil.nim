# test the new strutils module

import
  strutils

proc testStrip() =
  write(stdout, strip("  ha  "))

proc main() = 
  testStrip()
  for p in split("/home/a1:xyz:/usr/bin", {':'}):
    write(stdout, p)
    
    
main()
#OUT ha/home/a1xyz/usr/bin
