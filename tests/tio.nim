# test the file-IO

import
  io

proc main() =
  for line in lines("thallo.mor"):
    writeln(stdout, line)

main()
