# iterate over all files with a given filter:

import
  os, times

proc main(filter: string) =
  for filename in walkFiles(filter):
    writeln(stdout, filename)

  for key, val in iterOverEnvironment():
    writeln(stdout, key & '=' & val)

main("*.nim")
