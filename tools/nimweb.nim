#
#
#           Nimrod Website Generator
#        (c) Copyright 2012 Andreas Rumpf
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
    doc, srcdoc, srcdoc2, webdoc, pdf: seq[string]
    authors, projectName, projectTitle, logo, infile, outdir, ticker: string
    vars: PStringTable
    nimrodArgs: string

proc initConfigData(c: var TConfigData) =
  c.tabs = @[]
  c.links = @[]
  c.doc = @[]
  c.srcdoc = @[]
  c.srcdoc2 = @[]
  c.webdoc = @[]
  c.pdf = @[]
  c.infile = ""
  c.outdir = ""
  c.nimrodArgs = "--hint[Conf]:off "
  c.authors = ""
  c.projectTitle = ""
  c.projectName = ""
  c.logo = ""
  c.ticker = ""
  c.vars = newStringTable(modeStyleInsensitive)

include "sunset.tmpl"

# ------------------------- configuration file -------------------------------

const
  Version = "0.7"
  Usage = "nimweb - Nimrod Website Generator Version " & version & """

  (c) 2012 Andreas Rumpf
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
  var p = initOptParser()
  while true:
    next(p)
    var kind = p.kind
    var key = p.key
    var val = p.val
    case kind
    of cmdArgument:
      c.infile = addFileExt(key, "ini")
      c.nimrodArgs.add(cmdLineRest(p))
      break
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "help", "h": 
        stdout.write(Usage)
        quit(0)
      of "version", "v": 
        stdout.write(Version & "\n")
        quit(0)
      of "o", "output": c.outdir = val
      of "var":
        var idx = val.find('=')
        if idx < 0: quit("invalid command line")
        c.vars[substr(val, 0, idx-1)] = substr(val, idx+1)
      else: quit(Usage)
    of cmdEnd: break
  if c.infile.len == 0: quit(Usage)

proc walkDirRecursively(s: var seq[string], root, ext: string) =
  for k, f in walkDir(root):
    case k
    of pcFile, pcLinkToFile:
      if cmpIgnoreCase(ext, splitFile(f).ext) == 0:
        add(s, f)
    of pcDir: walkDirRecursively(s, f, ext)
    of pcLinkToDir: nil

proc addFiles(s: var seq[string], dir, ext: string, patterns: seq[string]) =
  for p in items(patterns):
    if existsDir(dir / p):
      walkDirRecursively(s, dir / p, ext)
    else:
      add(s, dir / addFileExt(p, ext))

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
          of "pdf": addFiles(c.pdf, "doc", ".txt", split(v, {';'}))
          of "srcdoc": addFiles(c.srcdoc, "lib", ".nim", split(v, {';'}))
          of "srcdoc2": addFiles(c.srcdoc2, "lib", ".nim", split(v, {';'}))
          of "webdoc": addFiles(c.webdoc, "lib", ".nim", split(v, {';'}))
          else: quit(errorStr(p, "unknown variable: " & k.key))
        else: nil

      of cfgOption: quit(errorStr(p, "syntax error"))
      of cfgError: quit(errorStr(p, k.msg))
    close(p)
    if c.projectName.len == 0:
      c.projectName = changeFileExt(extractFilename(c.infile), "")
    if c.outdir.len == 0:
      c.outdir = splitFile(c.infile).dir
  else:
    quit("cannot open: " & c.infile)

# ------------------- main ----------------------------------------------------

proc Exec(cmd: string) =
  echo(cmd)
  if os.execShellCmd(cmd) != 0: quit("external program failed")

proc buildDoc(c: var TConfigData, destPath: string) =
  # call nim for the documentation:
  for d in items(c.doc):
    Exec("nimrod rst2html $# -o:$# --index:on $#" %
      [c.nimrodArgs, destPath / changeFileExt(splitFile(d).name, "html"), d])
  for d in items(c.srcdoc):
    Exec("nimrod doc $# -o:$# --index:on $#" %
      [c.nimrodArgs, destPath / changeFileExt(splitFile(d).name, "html"), d])
  for d in items(c.srcdoc2):
    Exec("nimrod doc2 $# -o:$# --index:on $#" %
      [c.nimrodArgs, destPath / changeFileExt(splitFile(d).name, "html"), d])
  Exec("nimrod buildIndex -o:$1/theindex.html $1" % [destPath])

proc buildPdfDoc(c: var TConfigData, destPath: string) =
  if os.execShellCmd("pdflatex -version") != 0:
    echo "pdflatex not found; no PDF documentation generated"
  else:
    for d in items(c.pdf):
      Exec("nimrod rst2tex $# $#" % [c.nimrodArgs, d])
      # call LaTeX twice to get cross references right:
      Exec("pdflatex " & changeFileExt(d, "tex"))
      Exec("pdflatex " & changeFileExt(d, "tex"))
      # delete all the crappy temporary files:
      var pdf = splitFile(d).name & ".pdf"
      moveFile(dest=destPath / pdf, source=pdf)
      removeFile(changeFileExt(pdf, "aux"))
      if existsFile(changeFileExt(pdf, "toc")):
        removeFile(changeFileExt(pdf, "toc"))
      removeFile(changeFileExt(pdf, "log"))
      removeFile(changeFileExt(pdf, "out"))
      removeFile(changeFileExt(d, "tex"))

proc buildAddDoc(c: var TConfigData, destPath: string) =
  # build additional documentation (without the index):
  for d in items(c.webdoc):
    Exec("nimrod doc $# -o:$# $#" %
      [c.nimrodArgs, destPath / changeFileExt(splitFile(d).name, "html"), d])

proc main(c: var TConfigData) =
  const
    cmd = "nimrod rst2html --compileonly $1 -o:web/$2.temp web/$2.txt"
  if c.ticker.len > 0:
    Exec(cmd % [c.nimrodArgs, c.ticker])
    var temp = "web" / changeFileExt(c.ticker, "temp")
    try:
      c.ticker = readFile(temp)
    except EIO:
      quit("[Error] cannot open: " & temp)
    RemoveFile(temp)
  for i in 0..c.tabs.len-1:
    var file = c.tabs[i].val
    Exec(cmd % [c.nimrodArgs, file])
    var temp = "web" / changeFileExt(file, "temp")
    var content: string
    try:
      content = readFile(temp)
    except EIO:
      quit("[Error] cannot open: " & temp)
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
  buildPdfDoc(c, "doc")

var c: TConfigData
initConfigData(c)
parseCmdLine(c)
parseIniFile(c)
main(c)
