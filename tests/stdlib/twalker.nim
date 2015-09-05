# iterate over all files with a given filter:

import
  "../../lib/pure/os.nim", ../../ lib / pure / times

proc main(filter: string) =
  for filename in walkFiles(filter):
    writeLine(stdout, filename)

  for key, val in envPairs():
    writeLine(stdout, key & '=' & val)

main("*.nim")
