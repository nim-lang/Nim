discard """
disabled: false
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


block: # bug #19671
  let expected = "  12  "
                         # --bar:   "  12  "   --foo="  12  "  -a=   "  12  "   -s:"  12  "
  var p = initOptParser(@["--bar:", "  12  ", "--foo=  12  ", "-a=", "  12  ", "-b:  12  "])
  next(p)
  doAssert p.kind == cmdLongOption
  doAssert p.key  == "bar"
  doAssert p.val  == expected
  next(p)
  doAssert p.kind == cmdLongOption
  doAssert p.key  == "foo"
  doAssert p.val  == expected
  next(p)
  doAssert p.kind == cmdShortOption
  doAssert p.key  == "a"
  doAssert p.val  == expected
  next(p)
  doAssert p.kind == cmdShortOption
  doAssert p.key  == "b"
  doAssert p.val  == expected

                         # -ab    -e:5    --foo    --bar=20    file.txt
  var x = initOptParser(@["-ab", "-e:5", "--foo", "--bar=20", "file.txt"])
  next(x)
  doAssert x.kind == cmdShortOption
  doAssert x.key  == "a"
  doAssert x.val  == ""
  next(x)
  doAssert x.kind == cmdShortOption
  doAssert x.key  == "b"
  doAssert x.val  == ""
  next(x)
  doAssert x.kind == cmdShortOption
  doAssert x.key  == "e"
  doAssert x.val  == "5"
  next(x)
  doAssert x.kind == cmdLongOption
  doAssert x.key  == "foo"
  doAssert x.val  == ""
  next(x)
  doAssert x.kind == cmdLongOption
  doAssert x.key  == "bar"
  doAssert x.val  == "20"
  next(x)
  doAssert x.kind == cmdArgument
  doAssert x.key  == "file.txt"
  doAssert x.val  == ""

