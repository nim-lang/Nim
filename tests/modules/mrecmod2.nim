# Module B
import trecmod2

proc p*(x: trecmod2.T1): trecmod2.T1 =
  # this works because the compiler has already
  # added T1 to trecmod2's interface symbol table
  return x + 1


