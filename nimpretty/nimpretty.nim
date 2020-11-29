#
#
#           The Nim Compiler
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Standard tool for pretty printing.

when not defined(nimpretty):
  {.error: "This needs to be compiled with --define:nimPretty".}

import ../compiler / [idents, msgs, syntaxes, options, pathutils, layouter]

import parseopt, strutils, os, sequtils

const
  Version = "0.2"
  Usage = "nimpretty - Nim Pretty Printer Version " & Version & """

  (c) 2017 Andreas Rumpf
Usage:
  nimpretty [options] nimfiles...
Options:
  --out:file            set the output file (default: overwrite the input file)
  --outDir:dir          set the output dir (default: overwrite the input files)
  --indent:N[=0]        set the number of spaces that is used for indentation
                        --indent:0 means autodetection (default behaviour)
  --maxLineLen:N        set the desired maximum line length (default: 80)
  --version             show the version
  --help                show this help
"""

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write(Version & "\n")
  stdout.flushFile()
  quit(0)

type
  PrettyOptions* = object
    indWidth*: Natural
    maxLineLen*: Positive

proc prettyPrint*(infile, outfile: string, opt: PrettyOptions) =
  var conf = newConfigRef()
  let fileIdx = fileInfoIdx(conf, AbsoluteFile infile)
  let f = splitFile(outfile.expandTilde)
  conf.outFile = RelativeFile f.name & f.ext
  conf.outDir = toAbsoluteDir f.dir
  var parser: Parser
  parser.em.indWidth = opt.indWidth
  if setupParser(parser, fileIdx, newIdentCache(), conf):
    parser.em.maxLineLen = opt.maxLineLen
    discard parseAll(parser)
    closeParser(parser)

proc main =
  var outfile, outdir: string

  var infiles = newSeq[string]()
  var outfiles = newSeq[string]()

  var backup = false
    # when `on`, create a backup file of input in case
    # `prettyPrint` could over-write it (note that the backup may happen even
    # if input is not actually over-written, when nimpretty is a noop).
    # --backup was un-documented (rely on git instead).
  var opt = PrettyOptions(indWidth: 0, maxLineLen: 80)


  for kind, key, val in getopt():
    case kind
    of cmdArgument:
      infiles.add(key.addFileExt(".nim"))
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "help", "h": writeHelp()
      of "version", "v": writeVersion()
      of "backup": backup = parseBool(val)
      of "output", "o", "out": outfile = val
      of "outDir", "outdir": outdir = val
      of "indent": opt.indWidth = parseInt(val)
      of "maxlinelen": opt.maxLineLen = parseInt(val)
      else: writeHelp()
    of cmdEnd: assert(false) # cannot happen
  if infiles.len == 0:
    quit "[Error] no input file."

  if outfile.len != 0 and outdir.len != 0:
    quit "[Error] out and outDir cannot both be specified"

  if outfile.len == 0 and outdir.len == 0:
    outfiles = infiles
  elif outfile.len != 0 and infiles.len > 1:
    # Take the last file to maintain backwards compatibility
    let infile = infiles[^1]
    infiles = @[infile]
    outfiles = @[outfile]
  elif outfile.len != 0:
    outfiles = @[outfile]
  elif outdir.len != 0:
    outfiles = infiles.mapIt($(joinPath(outdir, it)))

  for (infile, outfile) in zip(infiles, outfiles):
    let (dir, _, _) = splitFile(outfile)
    createDir(dir)
    if not fileExists(outfile) or not sameFile(infile, outfile):
      backup = false # no backup needed since won't be over-written
    if backup:
      let infileBackup = infile & ".backup" # works with .nim or .nims
      echo "writing backup " & infile & " > " & infileBackup
      os.copyFile(source = infile, dest = infileBackup)
    prettyPrint(infile, outfile, opt)

when isMainModule:
  main()
