# bug #1595, #1612

import mexport2a

proc main() =
  echo "Import Test, two lines should follow. One with abc and one with xyz."
  printAbc()
  printXyz()

main()
foo(3)
