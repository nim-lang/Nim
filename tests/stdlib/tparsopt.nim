discard """
disabled: true
"""

# this file has a type in the name, and it does not really test
# parseopt module, because tester has no support to set arguments. Test the
# new parseopt module. Therefore it is disabled.

import
  parseopt

proc writeHelp() =
  writeLine(stdout, "Usage: tparsopt [options] filename [options]")

proc writeVersion() =
  writeLine(stdout, "Version: 1.0.0")

var
  filename = ""
for kind, key, val in getopt():
  case kind
  of cmdArgument:
    filename = key
  of cmdLongOption, cmdShortOption:
    case key
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
    else:
      writeLine(stdout, "Unknown command line option: ", key, ": ", val)
  of cmdEnd: doAssert(false) # cannot happen
if filename == "":
  # no filename has been given, so we show the help:
  writeHelp()
