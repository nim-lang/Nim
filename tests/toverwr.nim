# Test the overloading resolution in connection with a qualifier

proc write(t: tTextFile, s: string) =
  nil # a nop

system.write(stdout, "hallo")
#OUT hallo
