discard """
  output: "4"
"""
type
  T1* = int  # Module A exports the type ``T1``

import mrecmod2   # the compiler starts parsing B
# the manual says this should work
proc main() =
  echo p(3) # works because B has been parsed completely here

main()

