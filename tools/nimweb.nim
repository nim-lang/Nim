#
#
#           Nimrod Website Generator
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, times, parseopt, parsecfg, streams, strtabs

type
  TKeyValPair = tuple[key, val: string]
  TConfigData = object of TObject
    tabs, links: seq[TKeyValPair]
    doc, srcdoc, webdoc: seq[string]
    authors, projectName, projectTitle, logo, infile, outdir, ticker: string
    vars: PStringTable
    nimrodArgs: string

proc initConfigData(c: var TConfigData) =
  c.tabs = @[]
  c.links = @[]
  c.doc = @[]
  c.srcdoc = @[]
  c.webdoc = @[]
  c.infile = ""
  c.outdir = ""
  c.nimrodArgs = ""
  c.authors = ""
  c.projectTitle = ""
  c.projectName = ""
  c.logo = ""
  c.ticker = ""
  c.vars = newStringTable(modeStyleInsensitive)

include "sunset.tmpl"

# ------------------------- configuration file -------------------------------

const
  Version = "0.6"
  Usage = "nimweb - Nimrod Installation Generator Version " & version & """

  (c) 2008 Andreas Rumpf
Usage:
  nimweb [options] ini-file[.ini] [compile_options]
Options:
  -o, --output:dir    set the output directory (default: same as ini-file)
  --var:name=value    set the value of a variable
  -h, --help          shows this help
  -v, --version       shows the version
Compile_options:
  will be passed to the Nimrod compiler
"""

proc parseCmdLine(c: var TConfigData) =
  var p = init()
  while true:
    next(p)
    var kind = p.kind
    var key = p.key
    var val = p.val
    case kind
    of cmdArgument:
      c.infile = appendFileExt(key, "ini")
      c.nimrodArgs = getRestOfCommandLine(p)
      break
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "help", "h": write(stdout, Usage)
      of "version", "v": writeln(stdout, Version)
      of "o", "output": c.outdir = val
      of "var":
        var idx = val.find('=')
        if idx < 0: quit("invalid command line")
        c.vars[copy(val, 0, idx-1)] = copy(val, idx+1)
      else: quit(Usage)
    of cmdEnd: break
  if c.infile.len == 0: quit(Usage)

proc walkDirRecursively(s: var seq[string], root, ext: string) =
  for k, f in walkDir(root):
    case k
    of pcFile, pcLinkToFile:
      if cmpIgnoreCase(ext, extractFileExt(f)) == 0:
        add(s, f)
    of pcDirectory: walkDirRecursively(s, f, ext)
    of pcLinkToDirectory: nil

proc addFiles(s: var seq[string], dir, ext: string, patterns: seq[string]) =
  for p in items(patterns):
    if existsDir(dir / p):
      walkDirRecursively(s, dir / p, ext)
    else:
      add(s, dir / appendFileExt(p, ext))

proc parseIniFile(c: var TConfigData) =
  var
    p: TCfgParser
    section: string # current section
  var input = newFileStream(c.infile, fmRead)
  if input != nil:
    open(p, input, c.infile)
    while true:
      var k = next(p)
      case k.kind
      of cfgEof: break
      of cfgSectionStart:
        section = normalize(k.section)
        case section
        of "project", "links", "tabs", "ticker", "documentation", "var": nil
        else: echo("[Warning] Skipping unknown section: " & section)

      of cfgKeyValuePair:
        var v = k.value % c.vars
        c.vars[k.key] = v

        case section
        of "project":
          case normalize(k.key)
          of "name": c.projectName = v
          of "title": c.projectTitle = v
          of "logo": c.logo = v
          of "authors": c.authors = v
          else: quit(errorStr(p, "unknown variable: " & k.key))
        of "var": nil
        of "links": add(c.links, (k.key, v))
        of "tabs": add(c.tabs, (k.key, v))
        of "ticker": c.ticker = v
        of "documentation":
          case normalize(k.key)
          of "doc": addFiles(c.doc, "doc", ".txt", split(v, {';'}))
          of "srcdoc": addFiles(c.srcdoc, "lib", ".nim", split(v, {';'}))
          of "webdoc": addFiles(c.webdoc, "lib", ".nim", split(v, {';'}))
          else: quit(errorStr(p, "unknown variable: " & k.key))
        else: nil

      of cfgOption: quit(errorStr(p, "syntax error"))
      of cfgError: quit(errorStr(p, k.msg))
    close(p)
    if c.projectName.len == 0:
      c.projectName = changeFileExt(extractFilename(c.infile), "")
    if c.outdir.len == 0:
      c.outdir = extractDir(c.infile)
  else:
    quit("cannot open: " & c.infile)

# ------------------- main ----------------------------------------------------

proc Exec(cmd: string) =
  echo(cmd)
  if os.executeShellCommand(cmd) != 0: quit("external program failed")

proc buildDoc(c: var TConfigData, destPath: string) =
  # call nim for the documentation:
  for d in items(c.doc):
    Exec("nimrod rst2html $# -o:$# --index=$#/theindex $#" %
      [c.nimrodArgs, destPath / changeFileExt(extractFileTrunk(d), "html"),
       destpath, d])
    Exec("nimrod rst2tex $# $#" % [c.nimrodArgs, d])
  for d in items(c.srcdoc):
    Exec("nimrod doc $# -o:$# --index=$#/theindex $#" %
      [c.nimrodArgs, destPath / changeFileExt(extractFileTrunk(d), "html"),
       destpath, d])
  Exec("nimrod rst2html $1 -o:$2/theindex.html $2/theindex" %
       [c.nimrodArgs, destPath])

proc buildAddDoc(c: var TConfigData, destPath: string) =
  # build additional documentation (without the index):
  for d in items(c.webdoc):
    Exec("nimrod doc $# -o:$# $#" %
      [c.nimrodArgs, destPath / changeFileExt(extractFileTrunk(d), "html"), d])

proc main(c: var TConfigData) =
  const
    cmd = "nimrod rst2html --compileonly $1 -o:web/$2.temp web/$2.txt"
  if c.ticker.len > 0:
    Exec(cmd % [c.nimrodArgs, c.ticker])
    var temp = "web" / changeFileExt(c.ticker, "temp")
    c.ticker = readFile(temp)
    if isNil(c.ticker): quit("[Error] cannot open:" & temp)
    RemoveFile(temp)
  for i in 0..c.tabs.len-1:
    var file = c.tabs[i].val
    Exec(cmd % [c.nimrodArgs, file])
    var temp = "web" / changeFileExt(file, "temp")
    var content = readFile(temp)
    if isNil(content): quit("[Error] cannot open: " & temp)
    var f: TFile
    var outfile = "web/upload/$#.html" % file
    if open(f, outfile, fmWrite):
      writeln(f, generateHTMLPage(c, file, content))
      close(f)
    else:
      quit("[Error] cannot write file: " & outfile)
    removeFile(temp)

  buildAddDoc(c, "web/upload")
  buildDoc(c, "web/upload")
  buildDoc(c, "doc")

var c: TConfigData
initConfigData(c)
parseCmdLine(c)
parseIniFile(c)
main(c)
