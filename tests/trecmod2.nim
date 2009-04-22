type
  T1* = int  # Module A exports the type ``T1``

import mrecmod2   # the compiler starts parsing B

proc main() =
  var i = p(3) # works because B has been parsed completely here

main()

