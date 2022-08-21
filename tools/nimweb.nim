#
#
#           Nim Website Generator
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, times, parseopt, parsecfg, streams, strtabs, tables,
  re, htmlgen, macros, md5, osproc, parsecsv, algorithm

from xmltree import escape

type
  TKeyValPair = tuple[key, id, val: string]
  TConfigData = object of RootObj
    tabs, links: seq[TKeyValPair]
    doc, srcdoc, srcdoc2, webdoc, pdf: seq[string]
    authors, projectName, projectTitle, logo, infile, ticker: string
    vars: StringTableRef
    nimCompiler: string
    nimArgs: string
    gitURL: string
    docHTMLOutput: string
    webUploadOutput: string
    quotations: Table[string, tuple[quote, author: string]]
    numProcessors: int # Set by parallelBuild:n, only works for values > 0.
    gaId: string  # google analytics ID, nil means analytics are disabled
  TRssItem = object
    year, month, day, title, url, content: string
  TAction = enum
    actAll, actOnlyWebsite, actPdf, actJson2, actOnlyDocs

  Sponsor = object
    logo: string
    name: string
    url: string
    thisMonth: int
    allTime: int
    since: string
    level: int

var action: TAction

proc initConfigData(c: var TConfigData) =
  c.tabs = @[]
  c.links = @[]
  c.doc = @[]
  c.srcdoc = @[]
  c.srcdoc2 = @[]
  c.webdoc = @[]
  c.pdf = @[]
  c.infile = ""
  c.nimArgs = "--hint:Conf:off --hint:Path:off --hint:Processing:off -d:boot "
  c.gitURL = "https://github.com/nim-lang/Nim"
  c.docHTMLOutput = "doc/html"
  c.webUploadOutput = "web/upload"
  c.authors = ""
  c.projectTitle = ""
  c.projectName = ""
  c.logo = ""
  c.ticker = ""
  c.vars = newStringTable(modeStyleInsensitive)
  c.numProcessors = countProcessors()
  # Attempts to obtain the git current commit.
  when false:
    let (output, code) = execCmdEx("git log -n 1 --format=%H")
    if code == 0 and output.strip.len == 40:
      c.gitCommit = output.strip
  c.quotations = initTable[string, tuple[quote, author: string]]()

include "website.nimf"

# ------------------------- configuration file -------------------------------

const
  version = "0.8"
  usage = "nimweb - Nim Website Generator Version " & version & """

  (c) 2015 Andreas Rumpf
Usage:
  nimweb [options] ini-file[.ini] [compile_options]
Options:
  -h, --help          shows this help
  -v, --version       shows the version
  -o, --output        overrides output directory instead of default
                      web/upload and doc/html
  --nimCompiler       overrides nim compiler; default = bin/nim
  --var:name=value    set the value of a variable
  --website           only build the website, not the full documentation
  --pdf               build the PDF version of the documentation
  --json2             build JSON of the documentation
  --onlyDocs          build only the documentation
  --git.url           override base url in generated doc links
  --git.commit        override commit/branch in generated doc links 'source'
  --git.devel         override devel branch in generated doc links 'edit'
Compile_options:
  will be passed to the Nim compiler
"""

  rYearMonthDay = r"on\s+(\d{2})\/(\d{2})\/(\d{4})"
  rssUrl = "http://nim-lang.org/news.xml"
  rssNewsUrl = "http://nim-lang.org/news.html"
  activeSponsors = "web/sponsors.csv"
  inactiveSponsors = "web/inactive_sponsors.csv"
  validAnchorCharacters = Letters + Digits


macro id(e: untyped): untyped =
  ## generates the rss xml ``id`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "id")

macro updated(e: varargs[untyped]): untyped =
  ## generates the rss xml ``updated`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "updated")

proc updatedDate(year, month, day: string): string =
  ## wrapper around the update macro with easy input.
  result = updated("$1-$2-$3T00:00:00Z" % [year,
    repeat("0", 2 - len(month)) & month,
    repeat("0", 2 - len(day)) & day])

macro entry(e: varargs[untyped]): untyped =
  ## generates the rss xml ``entry`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "entry")

macro content(e: varargs[untyped]): untyped =
  ## generates the rss xml ``content`` element.
  let e = callsite()
  result = xmlCheckedTag(e, "content", reqAttr = "type")

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
      c.nimArgs.add(cmdLineRest(p))
      break
    of cmdLongOption, cmdShortOption:
      case normalize(key)
      of "help", "h":
        stdout.write(usage)
        quit(0)
      of "version", "v":
        stdout.write(version & "\n")
        quit(0)
      of "output", "o":
        c.webUploadOutput = val
        c.docHTMLOutput = val / "docs"
      of "nimcompiler":
        c.nimCompiler = val
      of "parallelbuild":
        try:
          let num = parseInt(val)
          if num != 0: c.numProcessors = num
        except ValueError:
          quit("invalid numeric value for --parallelBuild")
      of "var":
        var idx = val.find('=')
        if idx < 0: quit("invalid command line")
        c.vars[substr(val, 0, idx-1)] = substr(val, idx+1)
      of "website": action = actOnlyWebsite
      of "pdf": action = actPdf
      of "json2": action = actJson2
      of "onlydocs": action = actOnlyDocs
      of "googleanalytics":
        c.gaId = val
        c.nimArgs.add("--doc.googleAnalytics:" & val & " ")
      of "git.url":
        c.gitURL = val
      of "git.commit":
        c.nimArgs.add("--git.commit:" & val & " ")
      of "git.devel":
        c.nimArgs.add("--git.devel:" & val & " ")
      else:
        echo("Invalid argument '$1'" % [key])
        quit(usage)
    of cmdEnd: break
  if c.infile.len == 0: quit(usage)

proc walkDirRecursively(s: var seq[string], root, ext: string) =
  for k, f in walkDir(root):
    case k
    of pcFile, pcLinkToFile:
      if cmpIgnoreCase(ext, splitFile(f).ext) == 0:
        add(s, f)
    of pcDir: walkDirRecursively(s, f, ext)
    of pcLinkToDir: discard

proc addFiles(s: var seq[string], dir, ext: string, patterns: seq[string]) =
  for p in items(patterns):
    if fileExists(dir / addFileExt(p, ext)):
      s.add(dir / addFileExt(p, ext))
    if dirExists(dir / p):
      walkDirRecursively(s, dir / p, ext)

proc parseIniFile(c: var TConfigData) =
  var
    p: CfgParser
    section: string # current section
  var input = newFileStream(c.infile, fmRead)
  if input == nil: quit("cannot open: " & c.infile)
  open(p, input, c.infile)
  while true:
    var k = next(p)
    case k.kind
    of cfgEof: break
    of cfgSectionStart:
      section = normalize(k.section)
      case section
      of "project", "links", "tabs", "ticker", "documentation", "var": discard
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
      of "var": discard
      of "links":
        let valID = v.split(';')
        add(c.links, (k.key.replace('_', ' '), valID[1], valID[0]))
      of "tabs": add(c.tabs, (k.key, "", v))
      of "ticker": c.ticker = v
      of "documentation":
        case normalize(k.key)
        of "doc": addFiles(c.doc, "doc", ".rst", split(v, {';'}))
        of "pdf": addFiles(c.pdf, "doc", ".rst", split(v, {';'}))
        of "srcdoc": addFiles(c.srcdoc, "lib", ".nim", split(v, {';'}))
        of "srcdoc2": addFiles(c.srcdoc2, "lib", ".nim", split(v, {';'}))
        of "webdoc": addFiles(c.webdoc, "lib", ".nim", split(v, {';'}))
        of "parallelbuild":
          try:
            let num = parseInt(v)
            if num != 0: c.numProcessors = num
          except ValueError:
            quit("invalid numeric value for --parallelBuild in config")
        else: quit(errorStr(p, "unknown variable: " & k.key))
      of "quotations":
        let vSplit = v.split('-')
        doAssert vSplit.len == 2
        c.quotations[k.key.normalize] = (vSplit[0], vSplit[1])
      else: discard
    of cfgOption: quit(errorStr(p, "syntax error"))
    of cfgError: quit(errorStr(p, k.msg))
  close(p)
  if c.projectName.len == 0:
    c.projectName = changeFileExt(extractFilename(c.infile), "")

# ------------------- main ----------------------------------------------------


proc exe(f: string): string = return addFileExt(f, ExeExt)

proc findNim(c: TConfigData): string =
  if c.nimCompiler.len > 0: return c.nimCompiler
  var nim = "nim".exe
  result = "bin" / nim
  if fileExists(result): return
  for dir in split(getEnv("PATH"), PathSep):
    if fileExists(dir / nim): return dir / nim
  # assume there is a symlink to the exe or something:
  return nim

proc exec(cmd: string) =
  echo(cmd)
  let (outp, exitCode) = osproc.execCmdEx(cmd)
  if exitCode != 0: quit outp

proc sexec(cmds: openarray[string]) =
  ## Serial queue wrapper around exec.
  for cmd in cmds: exec(cmd)

proc mexec(cmds: openarray[string], processors: int) =
  ## Multiprocessor version of exec
  doAssert processors > 0, "nimweb needs at least one processor"
  if processors == 1:
    sexec(cmds)
    return
  let r = execProcesses(cmds, {poStdErrToStdOut, poParentStreams, poEchoCmd},
    n = processors)
  if r != 0:
    echo "external program failed, retrying serial work queue for logs!"
    sexec(cmds)

proc buildDocSamples(c: var TConfigData, destPath: string) =
  ## Special case documentation sample proc.
  ##
  ## TODO: consider integrating into the existing generic documentation builders
  ## now that we have a single `doc` command.
  exec(findNim(c) & " doc $# -o:$# $#" %
    [c.nimArgs, destPath / "docgen_sample.html", "doc" / "docgen_sample.nim"])

proc pathPart(d: string): string = splitFile(d).dir.replace('\\', '/')

proc buildDoc(c: var TConfigData, destPath: string) =
  # call nim for the documentation:
  var
    commands = newSeq[string](len(c.doc) + len(c.srcdoc) + len(c.srcdoc2))
    i = 0
  for d in items(c.doc):
    commands[i] = findNim(c) & " rst2html $# --git.url:$# -o:$# --index:on $#" %
      [c.nimArgs, c.gitURL,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc
  for d in items(c.srcdoc):
    commands[i] = findNim(c) & " doc0 $# --git.url:$# -o:$# --index:on $#" %
      [c.nimArgs, c.gitURL,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc
  for d in items(c.srcdoc2):
    commands[i] = findNim(c) & " doc $# --git.url:$# -o:$# --index:on $#" %
      [c.nimArgs, c.gitURL,
      destPath / changeFileExt(splitFile(d).name, "html"), d]
    i.inc

  mexec(commands, c.numProcessors)
  exec(findNim(c) & " buildIndex -o:$1/theindex.html $1" % [destPath])

proc buildPdfDoc(c: var TConfigData, destPath: string) =
  createDir(destPath)
  if os.execShellCmd("pdflatex -version") != 0:
    echo "pdflatex not found; no PDF documentation generated"
  else:
    const pdflatexcmd = "pdflatex -interaction=nonstopmode "
    for d in items(c.pdf):
      exec(findNim(c) & " rst2tex $# $#" % [c.nimArgs, d])
      # call LaTeX twice to get cross references right:
      exec(pdflatexcmd & changeFileExt(d, "tex"))
      exec(pdflatexcmd & changeFileExt(d, "tex"))
      # delete all the crappy temporary files:
      let pdf = splitFile(d).name & ".pdf"
      let dest = destPath / pdf
      removeFile(dest)
      moveFile(dest=dest, source=pdf)
      removeFile(changeFileExt(pdf, "aux"))
      if fileExists(changeFileExt(pdf, "toc")):
        removeFile(changeFileExt(pdf, "toc"))
      removeFile(changeFileExt(pdf, "log"))
      removeFile(changeFileExt(pdf, "out"))
      removeFile(changeFileExt(d, "tex"))

proc buildAddDoc(c: var TConfigData, destPath: string) =
  # build additional documentation (without the index):
  var commands = newSeq[string](c.webdoc.len)
  for i, doc in pairs(c.webdoc):
    commands[i] = findNim(c) & " doc $# --git.url:$# -o:$# $#" %
      [c.nimArgs, c.gitURL,
      destPath / changeFileExt(splitFile(doc).name, "html"), doc]
  mexec(commands, c.numProcessors)

proc parseNewsTitles(inputFilename: string): seq[TRssItem] =
  # Goes through each news file, returns its date/title.
  result = @[]
  var matches: array[3, string]
  let reYearMonthDay = re(rYearMonthDay)
  for kind, path in walkDir(inputFilename):
    let (dir, name, ext) = path.splitFile
    if ext == ".rst":
      let content = readFile(path)
      let title = content.splitLines()[0]
      let urlPath = "news/" & name & ".html"
      if content.find(reYearMonthDay, matches) >= 0:
        result.add(TRssItem(year: matches[2], month: matches[1], day: matches[0],
          title: title, url: "http://nim-lang.org/" & urlPath,
          content: content))
  result.reverse()

proc genUUID(text: string): string =
  # Returns a valid RSS uuid, which is basically md5 with dashes and a prefix.
  result = getMD5(text)
  result.insert("-", 20)
  result.insert("-", 16)
  result.insert("-", 12)
  result.insert("-", 8)
  result.insert("urn:uuid:")

proc genNewsLink(title: string): string =
  # Mangles a title string into an expected news.html anchor.
  result = title
  result.insert("Z")
  for i in 1..len(result)-1:
    let letter = result[i].toLowerAscii()
    if letter in validAnchorCharacters:
      result[i] = letter
    else:
      result[i] = '-'
  result.insert(rssNewsUrl & "#")

proc generateRss(outputFilename: string, news: seq[TRssItem]) =
  # Given a list of rss items generates an rss overwriting destination.
  var
    output: File

  if not open(output, outputFilename, mode = fmWrite):
    quit("Could not write to $1 for rss generation" % [outputFilename])
  defer: output.close()

  output.write("""<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
""")
  output.write(title("Nim website news"))
  output.write(link(href = rssUrl, rel = "self"))
  output.write(link(href = rssNewsUrl))
  output.write(id(rssNewsUrl))

  let now = utc(getTime())
  output.write(updatedDate($now.year, $(int(now.month) + 1), $now.monthday))

  for rss in news:
    output.write(entry(
        title(xmltree.escape(rss.title)),
        id(genUUID(rss.title)),
        link(`type` = "text/html", rel = "alternate",
          href = rss.url),
        updatedDate(rss.year, rss.month, rss.day),
        "<author><name>Nim</name></author>",
        content(xmltree.escape(rss.content), `type` = "text")
      ))

  output.write("""</feed>""")

proc buildNewsRss(c: var TConfigData, destPath: string) =
  # generates an xml feed from the web/news.rst file
  let
    srcFilename = "web" / "news"
    destFilename = destPath / changeFileExt(splitFile(srcFilename).name, "xml")

  generateRss(destFilename, parseNewsTitles(srcFilename))

proc readSponsors(sponsorsFile: string): seq[Sponsor] =
  result = @[]
  var fileStream = newFileStream(sponsorsFile, fmRead)
  if fileStream == nil: quit("Cannot open sponsors.csv file: " & sponsorsFile)
  var parser: CsvParser
  open(parser, fileStream, sponsorsFile)
  discard readRow(parser) # Skip the header row.
  while readRow(parser):
    result.add(Sponsor(logo: parser.row[0], name: parser.row[1],
        url: parser.row[2], thisMonth: parser.row[3].parseInt,
        allTime: parser.row[4].parseInt,
        since: parser.row[5], level: parser.row[6].parseInt))
  parser.close()

proc buildSponsors(c: var TConfigData, outputDir: string) =
  let sponsors = generateSponsorsPage(readSponsors(activeSponsors),
                                      readSponsors(inactiveSponsors))
  let outFile = outputDir / "sponsors.html"
  var f: File
  if open(f, outFile, fmWrite):
    writeLine(f, generateHtmlPage(c, "", "Our Sponsors", sponsors, ""))
    close(f)
  else:
    quit("[Error] Cannot write file: " & outFile)

const
  cmdRst2Html = " rst2html --compileonly $1 -o:web/$2.temp web/$2.rst"

proc buildPage(c: var TConfigData, file, title, rss: string, assetDir = "") =
  exec(findNim(c) & cmdRst2Html % [c.nimArgs, file])
  var temp = "web" / changeFileExt(file, "temp")
  var content: string
  try:
    content = readFile(temp)
  except IOError:
    quit("[Error] cannot open: " & temp)
  var f: File
  var outfile = c.webUploadOutput / "$#.html" % file
  if not dirExists(outfile.splitFile.dir):
    createDir(outfile.splitFile.dir)
  if open(f, outfile, fmWrite):
    writeLine(f, generateHTMLPage(c, file, title, content, rss, assetDir))
    close(f)
  else:
    quit("[Error] cannot write file: " & outfile)
  removeFile(temp)

proc buildNews(c: var TConfigData, newsDir: string, outputDir: string) =
  for kind, path in walkDir(newsDir):
    let (dir, name, ext) = path.splitFile
    if ext == ".rst":
      let title = readFile(path).splitLines()[0]
      buildPage(c, tailDir(dir) / name, title, "", "../")
    else:
      echo("Skipping file in news directory: ", path)

proc buildWebsite(c: var TConfigData) =
  if c.ticker.len > 0:
    try:
      c.ticker = readFile("web" / c.ticker)
    except IOError:
      quit("[Error] cannot open: " & c.ticker)
  for i in 0..c.tabs.len-1:
    var file = c.tabs[i].val
    let rss = if file in ["news", "index"]: extractFilename(rssUrl) else: ""
    if '.' in file: continue
    buildPage(c, file, if file == "question": "FAQ" else: file, rss)
  copyDir("web/assets", c.webUploadOutput / "assets")
  buildNewsRss(c, c.webUploadOutput)
  buildSponsors(c, c.webUploadOutput)
  buildNews(c, "web/news", c.webUploadOutput / "news")

proc onlyDocs(c: var TConfigData) =
  createDir(c.docHTMLOutput)
  buildDocSamples(c, c.docHTMLOutput)
  buildDoc(c, c.docHTMLOutput)

proc main(c: var TConfigData) =
  buildWebsite(c)
  let docup = c.webUploadOutput / NimVersion
  createDir(docup)
  buildAddDoc(c, docup)
  buildDocSamples(c, docup)
  buildDoc(c, docup)
  onlyDocs(c)

proc json2(c: var TConfigData) =
  const destPath = "web/json2"
  var commands = newSeq[string](c.srcdoc2.len)
  var i = 0
  for d in items(c.srcdoc2):
    createDir(destPath / splitFile(d).dir)
    commands[i] = findNim(c) & " jsondoc $# --git.url:$# -o:$# --index:on $#" %
      [c.nimArgs, c.gitURL,
      destPath / changeFileExt(d, "json"), d]
    i.inc

  mexec(commands, c.numProcessors)

var c: TConfigData
initConfigData(c)
parseCmdLine(c)
parseIniFile(c)
case action
of actOnlyWebsite: buildWebsite(c)
of actPdf: buildPdfDoc(c, "doc/pdf")
of actOnlyDocs: onlyDocs(c)
of actAll: main(c)
of actJson2: json2(c)
