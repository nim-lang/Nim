discard """
  file: "tparsopt.nim"
"""
# Test the new parseopt module

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
