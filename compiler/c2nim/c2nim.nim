#
#
#      c2nim - C to Nimrod source converter
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  strutils, os, times, parseopt, llstream, ast, renderer, options, msgs,
  clex, cparse

const
  Version = NimrodVersion
  Usage = """
c2nim - C to Nimrod source converter
  (c) 2013 Andreas Rumpf
Usage: c2nim [options] inputfile [options]
Options:
  -o, --out:FILE         set output filename
  --cpp                  process C++ input file
  --dynlib:SYMBOL        import from dynlib: SYMBOL will be used for the import
  --header:HEADER_FILE   import from a HEADER_FILE (discouraged!)
  --cdecl                annotate procs with ``{.cdecl.}``
  --stdcall              annotate procs with ``{.stdcall.}``
  --ref                  convert typ* to ref typ (default: ptr typ)
  --prefix:PREFIX        strip prefix for the generated Nimrod identifiers
                         (multiple --prefix options are supported)
  --suffix:SUFFIX        strip suffix for the generated Nimrod identifiers
                         (multiple --suffix options are supported)
  --skipinclude          do not convert ``#include`` to ``import``
  --typeprefixes         generate ``T`` and ``P`` type prefixes
  --skipcomments         do not copy comments
  --ignoreRValueRefs     translate C++'s ``T&&`` to ``T`` instead ``of var T``
  --keepBodies           keep C++'s method bodies
  -v, --version          write c2nim's version
  -h, --help             show this help
"""

proc main(infile, outfile: string, options: PParserOptions) =
  var start = getTime()
  var stream = llStreamOpen(infile, fmRead)
  if stream == nil: rawMessage(errCannotOpenFile, infile)
  var p: TParser
  openParser(p, infile, stream, options)
  var module = parseUnit(p)
  closeParser(p)
  renderModule(module, outfile)
  rawMessage(hintSuccessX, [$gLinesCompiled, $(getTime() - start), 
                            formatSize(getTotalMem())])

var
  infile = ""
  outfile = ""
  parserOptions = newParserOptions()
for kind, key, val in getopt():
  case kind
  of cmdArgument: infile = key
  of cmdLongOption, cmdShortOption:
    case key.toLower
    of "help", "h":
      stdout.write(Usage)
      quit(0)
    of "version", "v":
      stdout.write(Version & "\n")
      quit(0)
    of "o", "out": outfile = val
    else:
      if not parserOptions.setOption(key, val):
        stdout.writeln("[Error] unknown option: " & key)
  of cmdEnd: assert(false)
if infile.len == 0:
  # no filename has been given, so we show the help:
  stdout.write(Usage)
else:
  if outfile.len == 0:
    outfile = changeFileExt(infile, "nim")
  infile = addFileExt(infile, "h")
  main(infile, outfile, parserOptions)
