# Test the new parseopt module

import
  parseopt

proc writeHelp() =
  writeln(stdout, "Usage: tparsopt [options] filename [options]")

proc writeVersion() =
  writeln(stdout, "Version: 1.0.0")

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
      writeln(stdout, "Unknown command line option: ", key, ": ", val)
  of cmdEnd: assert(false) # cannot happen
if filename == "":
  # no filename has been given, so we show the help:
  writeHelp()
