# iterate over all files with a given filter:

import
  io, os, times

proc main(filter: string) =
  for filename in walkFiles(filter):
    writeln(stdout, filename)

  for key, val in iterOverEnvironment():
    writeln(stdout, key & '=' & val)

main("*.mor")
