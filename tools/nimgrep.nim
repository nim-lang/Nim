#
#
#           Nim Grep Utility
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, parseopt, pegs, re, terminal, osproc, tables, algorithm, times

const
  Version = "1.6"
  Usage = "nimgrep - Nim Grep Utility Version " & Version & """

  (c) 2012 Andreas Rumpf
Usage:
  nimgrep [options] pattern [replacement] (file/directory)*
Options:
  --find, -f          find the pattern (default)
  --replace, -!       replace the pattern
  --peg               pattern is a peg
  --re                pattern is a regular expression (default)
  --rex, -x           use the "extended" syntax for the regular expression
                      so that whitespace is not significant
  --recursive, -r     process directories recursively
  --follow            follow all symlinks when processing recursively
  --confirm           confirm each occurrence/replacement; there is a chance
                      to abort any time without touching the file
  --stdin             read pattern from stdin (to avoid the shell's confusing
                      quoting rules)
  --word, -w          the match should have word boundaries (buggy for pegs!)
  --ignoreCase, -i    be case insensitive
  --ignoreStyle, -y   be style insensitive
  --nWorkers:N, -n:N  speed up search by N additional workers (threads)
  --ext:EX1|EX2|...   only search the files with the given extension(s),
                      empty one ("--ext") means files with missing extension
  --noExt:EX1|...     exclude files having given extension(s), use empty one to
                      skip files with no extension (like some binary files are)
  --includeFile:PAT   include only files whose names match the given PATttern
  --excludeFile:PAT   skip files whose names match the given pattern PAT
  --excludeDir:PAT    skip directories whose names match the given pattern PAT
  --match:PAT, -m:PAT select files containing a (not displayed) match of PAT
  --noMatch:PAT       select files not containing any match of PAT
  --bin:yes|no|only   process binary files? (detected by \0 in first 1K bytes)
  --text, -t          process only text files, the same as --bin:no
  --count             just count number of matches
  --nocolor           output will be given without any colours
  --color[:always]    force color even if output is redirected
  --colorTheme:THEME  select color THEME from 'simple' (default),
                      'bnw' (black and white) ,'ack', or 'gnu' (GNU grep)
  --afterContext:N,
               -a:N   print N lines of trailing context after every match
  --beforeContext:N,
               -b:N   print N lines of leading context before every match
  --context:N, -c:N   print N lines of leading context before every match and
                      N lines of trailing context after it
  --sortTime          order files by the last modification time -
       -s[:desc|asc]  - descending (default) or ascending
  --group, -g         group matches by file
  --newLine, -l       display every matching line starting from a new line
  --verbose           be verbose: list every processed file
  --filenames         find the pattern in the filenames, not in the contents
                      of the file
  --help, -h          shows this help
  --version, -v       shows the version
"""

type
  TOption = enum
    optFind, optReplace, optPeg, optRegex, optRecursive, optConfirm, optStdin,
    optWord, optIgnoreCase, optIgnoreStyle, optVerbose, optFilenames,
    optRex, optFollow
  TOptions = set[TOption]
  TConfirmEnum = enum
    ceAbort, ceYes, ceAll, ceNo, ceNone
  Bin = enum
    biYes, biOnly, biNo
  Pattern = Regex | Peg
  SearchInfo = tuple[buf: string, filename: string]
  MatchInfo = tuple[first: int, last: int;
                    lineBeg: int, lineEnd: int, match: string]
  outputKind = enum
    OpenError, Rejected, JustCount,
    GroupFirstMatch, GroupNextMatch, GroupEnd, FileContents
  Output = object
    case kind: outputKind
    of OpenError: msg: string
    of Rejected: discard
    of JustCount: matches: int
    of GroupFirstMatch, GroupNextMatch:
      pre: string
      match: MatchInfo
    of GroupEnd:
      groupEnding: string
      firstLine: int       # = last lineNo of last match
    of FileContents:
      buffer: string
  Trequest = (int, string)
  Tresult = tuple[finished: bool, fileNo: int,
                  filename: string, fileResult: seq[Output]]
  WalkOpt = tuple  # used for walking directories/producing paths
    extensions: seq[string]
    skipExtensions: seq[string]
    excludeFile: seq[string]
    includeFile: seq[string]
    excludeDir : seq[string]
  WalkOptComp[Pat] = tuple  # a compiled version of the previous
    excludeFile: seq[Pat]
    includeFile: seq[Pat]
    excludeDir : seq[Pat]
  SearchOpt = tuple  # used for searching inside a file
    pattern: string
    checkMatch: string
    checkNoMatch: string
    checkBin: Bin
  SearchOptComp[Pat] = tuple  # a compiled version of the previous
    pattern: Pat
    checkMatch: Pat
    checkNoMatch: Pat

var
  paths: seq[string] = @[]
  replacement = ""
  options: TOptions = {optRegex}
  walkOpt {.threadvar.}: WalkOpt
  searchOpt {.threadvar.}: SearchOpt
  justCount = false
  sortTime = false
  sortTimeOrder = SortOrder.Descending
  useWriteStyled = true
  oneline = true
  linesBefore = 0
  linesAfter = 0
  linesContext = 0
  newLine = false
  gVar = (matches: 0, errors: 0, reallyReplace: false)
    # gVar - variables that can change during search/replace
  nWorkers = 0  # run in single thread by default
  searchRequestsChan: Channel[Trequest]
  resultsChan: Channel[Tresult]
  colorTheme: string = "simple"

searchOpt.checkBin = biYes

proc ask(msg: string): string =
  stdout.write(msg)
  stdout.flushFile()
  result = stdin.readLine()

proc confirm: TConfirmEnum =
  while true:
    case normalize(ask("     [a]bort; [y]es, a[l]l, [n]o, non[e]: "))
    of "a", "abort": return ceAbort
    of "y", "yes": return ceYes
    of "l", "all": return ceAll
    of "n", "no": return ceNo
    of "e", "none": return ceNone
    else: discard

func countLineBreaks(s: string, first, last: int): int =
  # count line breaks (unlike strutils.countLines starts count from 0)
  var i = first
  while i <= last:
    if s[i] == '\c':
      inc result
      if i < last and s[i+1] == '\l': inc(i)
    elif s[i] == '\l':
      inc result
    inc i

func beforePattern(s: string, pos: int, nLines = 1): int =
  var linesLeft = nLines
  result = min(pos, s.len-1)
  while true:
    while result >= 0 and s[result] notin {'\c', '\l'}: dec(result)
    if result == -1: break
    if s[result] == '\l':
      dec(linesLeft)
      if linesLeft == 0: break
      dec(result)
      if result >= 0 and s[result] == '\c': dec(result)
    else: # '\c'
      dec(linesLeft)
      if linesLeft == 0: break
      dec(result)
  inc(result)

proc afterPattern(s: string, pos: int, nLines = 1): int =
  result = max(0, pos)
  var linesScanned = 0
  while true:
    while result < s.len and s[result] notin {'\c', '\l'}: inc(result)
    inc(linesScanned)
    if linesScanned == nLines: break
    if result < s.len:
      if s[result] == '\l':
        inc(result)
      elif s[result] == '\c':
        inc(result)
        if result < s.len and s[result] == '\l': inc(result)
    else: break
  dec(result)

template whenColors(body: untyped) =
  if useWriteStyled:
    body
  else:
    stdout.write(s)

proc printFile(s: string) =
  whenColors:
    case colorTheme
    of "simple": stdout.write(s)
    of "bnw": stdout.styledWrite(styleUnderscore, s)
    of "ack": stdout.styledWrite(fgGreen, s)
    of "gnu": stdout.styledWrite(fgMagenta, s)

proc printBlockFile(s: string) =
  whenColors:
    case colorTheme
    of "simple": stdout.styledWrite(styleBright, s)
    of "bnw": stdout.styledWrite(styleUnderscore, s)
    of "ack": stdout.styledWrite(styleUnderscore, fgGreen, s)
    of "gnu": stdout.styledWrite(styleUnderscore, fgMagenta, s)

proc printError(s: string) =
  whenColors:
    case colorTheme
    of "simple", "bnw": stdout.styledWriteLine(styleBright, s)
    of "ack", "gnu": stdout.styledWriteLine(styleReverse, fgRed, bgDefault, s)
  stdout.flushFile()

const alignment = 6

proc printLineN(s: string, isMatch: bool) =
  whenColors:
    case colorTheme
    of "simple": stdout.write(s)
    of "bnw":
      if isMatch: stdout.styledWrite(styleBright, s)
      else: stdout.styledWrite(s)
    of "ack":
      if isMatch: stdout.styledWrite(fgYellow, s)
      else: stdout.styledWrite(fgGreen, s)
    of "gnu":
      if isMatch: stdout.styledWrite(fgGreen, s)
      else: stdout.styledWrite(fgCyan, s)

proc printBlockLineN(s: string) =
  whenColors:
    case colorTheme
    of "simple": stdout.styledWrite(styleBright, s)
    of "bnw": stdout.styledWrite(styleUnderscore, styleBright, s)
    of "ack": stdout.styledWrite(styleUnderscore, fgYellow, s)
    of "gnu": stdout.styledWrite(styleUnderscore, fgGreen, s)

proc writeColored(s: string) =
  whenColors:
    case colorTheme
    of "simple": terminal.writeStyled(s, {styleUnderscore, styleBright})
    of "bnw": stdout.styledWrite(styleReverse, s)
    # Try styleReverse & bgDefault as a work-around against nasty feature
    # "Background color erase" (sticky background after line wraps):
    of "ack": stdout.styledWrite(styleReverse, fgYellow, bgDefault, s)
    of "gnu": stdout.styledWrite(fgRed, s)

proc writeArrow(s: string) =
  whenColors:
    stdout.styledWrite(styleReverse, s)

proc blockHeader(filename: string, line: int|string, replMode=false) =
  if replMode:
    writeArrow("     ->\n")
  elif newLine and optFilenames notin options:
    if oneline:
      printBlockFile(filename)
      printBlockLineN(":" & $line & ":")
    else:
      printBlockLineN($line.`$`.align(alignment) & ":")
    stdout.write("\n")

proc lineHeader(filename: string, line: int|string, isMatch: bool) =
  let lineSym =
    if isMatch: $line & ":"
    else: $line & " "
  if not newLine and optFilenames notin options:
    if oneline:
      printFile(filename)
      printLineN(":" & lineSym, isMatch)
    else:
      printLineN(lineSym.align(alignment+1), isMatch)
    stdout.write(" ")

proc printMatch(fileName: string, mi: MatchInfo) =
  let lines = mi.match.splitLines()
  for i, l in lines:
    if i > 0:
      lineHeader(filename, mi.lineBeg + i, isMatch = true)
    writeColored(l)
    if i < lines.len - 1:
      stdout.write("\n")

proc getLinesBefore(si: SearchInfo, curMi: MatchInfo): string =
  let first = beforePattern(si.buf, curMi.first-1, linesBefore+1)
  result = substr(si.buf, first, curMi.first-1)

proc printLinesBefore(filename: string, beforeMatch: string, lineBeg: int, replMode=false) =
  # start block: print 'linesBefore' lines before current match `curMi`
  let lines = splitLines(beforeMatch)
  let startLine = lineBeg - lines.len + 1
  blockHeader(filename, lineBeg, replMode=replMode)
  for i, l in lines:
    lineHeader(filename, startLine + i, isMatch = (i == lines.len - 1))
    stdout.write(l)
    if i < lines.len - 1:
      stdout.write("\n")

proc getLinesAfter(si: SearchInfo, mi: MatchInfo): string =
  let last = afterPattern(si.buf, mi.last+1, 1+linesAfter)
  result = substr(si.buf, mi.last+1, last)

proc printLinesAfter(filename: string, afterMatch: string, matchLineEnd: int) =
  # finish block: print 'linesAfter' lines after match `mi`
  let lines = splitLines(afterMatch)
  if lines.len == 0: # EOF
    stdout.write("\n")
  else:
    stdout.write(lines[0]) # complete the line after match itself
    stdout.write("\n")
    #let skipLine =  # workaround posix line ending at the end of file
    #  if last == s.len-1 and s.len >= 2 and s[^1] == '\l' and s[^2] != '\c': 1
    #  else: 0
    let skipLine = 0
    for i in 1 ..< lines.len - skipLine:
      lineHeader(filename, matchLineEnd + i, isMatch = false)
      stdout.write(lines[i])
      stdout.write("\n")
  if linesAfter + linesBefore >= 2 and not newLine: stdout.write("\n")

proc getLinesBetween(si: SearchInfo, prevMi: MatchInfo, curMi: MatchInfo): string =
  si.buf.substr(prevMi.last+1, curMi.first-1)

proc printBetweenMatches(filename: string, betweenMatches: string, lastLineBeg: int) =
  # continue block: print between `prevMi` and `curMi`
  let lines = betweenMatches.splitLines()
  stdout.write(lines[0]) # finish the line of previous Match
  if lines.len > 1:
    stdout.write("\n")
    for i in 1 ..< lines.len:
      lineHeader(filename, lastLineBeg - lines.len + i + 1,
                 isMatch = (i == lines.len - 1))
      stdout.write(lines[i])
      if i < lines.len - 1:
        stdout.write("\n")

proc printReplacement(si: SearchInfo, mi: MatchInfo, repl: string,
                      showRepl: bool, curPos: int,
                      newBuf: string, curLine: int) =
  let filename = si.fileName
  printLinesBefore(fileName, getLinesBefore(si, mi), mi.lineBeg)
  printMatch(fileName, mi)
  printLinesAfter(fileName, getLinesAfter(si, mi), mi.lineEnd)
  stdout.flushFile()
  if showRepl:
    let newSi: SearchInfo = (buf: newBuf, filename: filename)
    let miForNewBuf: MatchInfo =
      (first: newBuf.len, last: newBuf.len,
       lineBeg: curLine, lineEnd: curLine, match: "")
    printLinesBefore(fileName, getLinesBefore(newSi, miForNewBuf), miForNewBuf.lineBeg, replMode=true)

    let replLines = countLineBreaks(repl, 0, repl.len-1)
    let miFixLines: MatchInfo =
      (first: mi.first, last: mi.last,
       lineBeg: curLine, lineEnd: curLine + replLines, match: repl)
    printMatch(fileName, miFixLines)
    printLinesAfter(fileName, getLinesAfter(si, miFixLines), miFixLines.lineEnd)
    stdout.flushFile()

proc replace1match(si: SearchInfo, mi: MatchInfo, i: int, r: string;
               newBuf: var string, curLine: var int): bool =
  newBuf.add(si.buf.substr(i, mi.first-1))
  inc(curLine, countLineBreaks(si.buf, i, mi.first-1))
  if optConfirm in options:
    printReplacement(si, mi, r, showRepl=true, i, newBuf, curLine)
    case confirm()
    of ceAbort: quit(0)
    of ceYes: gVar.reallyReplace = true
    of ceAll:
      gVar.reallyReplace = true
      options.excl(optConfirm)
    of ceNo:
      gVar.reallyReplace = false
    of ceNone:
      gVar.reallyReplace = false
      options.excl(optConfirm)
  else:
    printReplacement(si, mi, r, showRepl=gVar.reallyReplace, i, newBuf, curLine)
  if gVar.reallyReplace:
    result = true
    newBuf.add(r)
    inc(curLine, countLineBreaks(r, 0, r.len-1))
  else:
    newBuf.add(mi.match)
    inc(curLine, countLineBreaks(mi.match, 0, mi.match.len-1))

template updateCounters(output: Output) =
  case output.kind
  of GroupFirstMatch, GroupNextMatch: inc(gVar.matches)
  of JustCount: inc(gVar.matches, output.matches)
  of OpenError: inc(gVar.errors)
  of Rejected, GroupEnd, FileContents: discard

proc printOutput(filename: string, output: Output) =
  case output.kind
  of OpenError:
    printError("can not open path " & filename & " " & output.msg)
  of Rejected: discard
  of JustCount:
    echo " (" & $output.matches & " matches)"
  of FileContents: discard # impossible
  of GroupFirstMatch:
    printLinesBefore(filename, output.pre, output.match.lineBeg)
    printMatch(filename, output.match)
    #flush: TODO
  of GroupNextMatch:
    printBetweenMatches(filename, output.pre, output.match.lineBeg)
    printMatch(filename, output.match)
  of GroupEnd:
    printLinesAfter(filename, output.groupEnding, output.firstLine)

iterator searchFile(pattern: Pattern; filename: string; buffer: string): Output =
  let si: SearchInfo = (buf: buffer, filename: filename)
  var prevMi, curMi: MatchInfo
  curMi.lineEnd = 1
  var i = 0
  var matches: array[0..re.MaxSubpatterns-1, string]
  for j in 0..high(matches): matches[j] = ""
  while true:
    let t = findBounds(buffer, pattern, matches, i)
    if t.first < 0 or t.last < t.first:
      if prevMi.lineBeg != 0: # finalize last match
        yield Output(kind: GroupEnd,
                     groupEnding: getLinesAfter(si, prevMi),
                     firstLine: prevMi.lineEnd)
      break

    let lineBeg = curMi.lineEnd + countLineBreaks(buffer, i, t.first-1)
    curMi = (first: t.first,
             last: t.last,
             lineBeg: lineBeg,
             lineEnd: lineBeg + countLineBreaks(buffer, t.first, t.last),
             match: buffer.substr(t.first, t.last))
    if prevMi.lineBeg == 0: # no prev. match, so no prev. block to finalize
      yield Output(kind: GroupFirstMatch,
                   pre: getLinesBefore(si, curMi),
                   match: curMi)
    else:
      let nLinesBetween = curMi.lineBeg - prevMi.lineEnd
      if nLinesBetween <= linesAfter + linesBefore + 1: # print as 1 block
        yield Output(kind: GroupNextMatch,
                     pre: getLinesBetween(si, prevMi, curMi),
                     match: curMi)
      else: # finalize previous block and then print next block
        yield Output(kind: GroupEnd,
                     groupEnding: getLinesAfter(si, prevMi),
                     firstLine: prevMi.lineEnd)
        yield Output(kind: GroupFirstMatch,
                     pre: getLinesBefore(si, curMi),
                     match: curMi)

    i = t.last+1
    prevMi = curMi

func detectBin(buffer: string): bool =
  for i in 0 ..< min(1024, buffer.len):
    if buffer[i] == '\0':
      return true

proc compilePeg(initPattern: string): Peg =
  var pattern = initPattern
  if optWord in options:
    pattern = r"(^ / !\letter)(" & pattern & r") !\letter"
  if optIgnoreStyle in options:
    pattern = "\\y " & pattern
  elif optIgnoreCase in options:
    pattern = "\\i " & pattern
  result = peg(pattern)

proc styleInsensitive(s: string): string =
  template addx =
    result.add(s[i])
    inc(i)
  result = ""
  var i = 0
  var brackets = 0
  while i < s.len:
    case s[i]
    of 'A'..'Z', 'a'..'z', '0'..'9':
      addx()
      if brackets == 0: result.add("_?")
    of '_':
      addx()
      result.add('?')
    of '[':
      addx()
      inc(brackets)
    of ']':
      addx()
      if brackets > 0: dec(brackets)
    of '?':
      addx()
      if s[i] == '<':
        addx()
        while s[i] != '>' and s[i] != '\0': addx()
    of '\\':
      addx()
      if s[i] in strutils.Digits:
        while s[i] in strutils.Digits: addx()
      else:
        addx()
    else: addx()

proc compileRegex(initPattern: string): Regex =
  var pattern = initPattern
  var reflags = {reStudy}
  if optIgnoreStyle in options:
    pattern = styleInsensitive(pattern)
  if optWord in options:
    # see https://github.com/nim-lang/Nim/issues/13528#issuecomment-592786443
    pattern = r"(^|\W)(:?" & pattern & r")($|\W)"
  if {optIgnoreCase, optIgnoreStyle} * options != {}:
    reflags.incl reIgnoreCase
  result = if optRex in options: rex(pattern, reflags)
           else: re(pattern, reflags)

template declareCompiledPatterns(compiledStruct: untyped,
                                 StructType: untyped,
                                 body: untyped) =
  if optRegex notin options:
    var compiledStruct: StructType[Peg]
    proc compile(p: string): Peg = p.compilePeg()
    proc compileArray(initPattern: seq[string]): seq[Peg] =
      for pat in initPattern:
        result.add pat.compilePeg()
    body
  else:
    var compiledStruct: StructType[Regex]
    proc compile(p: string): Regex = p.compileRegex()
    proc compileArray(initPattern: seq[string]): seq[Regex] =
      for pat in initPattern:
        result.add pat.compileRegex()
    body

iterator processFile(searchOptC: SearchOptComp[Pattern], filename: string, yieldContents=false): Output =
  var buffer: string

  if optFilenames in options:
    buffer = filename
  else:
    try:
      buffer = system.readFile(filename)
    except IOError as e:
      yield Output(kind: OpenError, msg: e.msg)

  var reject = false
  if searchOpt.checkBin in {biNo, biOnly}:
    let isBin = detectBin(buffer)
    if isBin and searchOpt.checkBin == biNo:
      reject = true
    if (not isBin) and searchOpt.checkBin == biOnly:
      reject = true

  if not reject:
    if searchOpt.checkMatch != "":
      reject = not contains(buffer, searchOptC.checkMatch, 0)

  if not reject:
    if searchOpt.checkNoMatch != "":
      reject = contains(buffer, searchOptC.checkNoMatch, 0)

  if reject:
    yield Output(kind: Rejected)
  else:
    var found = false
    var cnt = 0
    for output in searchFile(searchOptC.pattern, filename, buffer):
      found = true
      if not justCount:
        yield output
      else:
        if output.kind in {GroupFirstMatch, GroupNextMatch}:
          inc(cnt)
    if justCount and cnt > 0:
      yield Output(kind: JustCount, matches: cnt)
    if yieldContents and found and not justCount:
      yield Output(kind: FileContents, buffer: buffer)

proc hasRightFileName(path: string, walkOptC: WalkOptComp[Pattern]): bool =
  let filename = path.lastPathPart
  let ex = filename.splitFile.ext.substr(1) # skip leading '.'
  if walkOpt.extensions.len != 0:
    var matched = false
    for x in walkOpt.extensions:
      if os.cmpPaths(x, ex) == 0:
        matched = true
        break
    if not matched: return false
  for x in walkOpt.skipExtensions:
    if os.cmpPaths(x, ex) == 0: return false
  if walkOptC.includeFile.len != 0:
    var matched = false
    for pat in walkOptC.includeFile:
      if filename.match(pat):
        matched = true
        break
    if not matched: return false
  for pat in walkOptC.excludeFile:
    if filename.match(pat): return false
  result = true

proc hasRightDirectory(path: string, walkOptC: WalkOptComp[Pattern]): bool =
  let dirname = path.lastPathPart
  for pat in walkOptC.excludeDir:
    if dirname.match(pat): return false
  result = true

iterator walkDirBasic(dir: string, walkOptC: WalkOptComp[Pattern]): string =
  var dirStack = @[dir]  # stack of directories
  var timeFiles = newSeq[(times.Time, string)]()
  while dirStack.len > 0:
    let d = dirStack.pop()
    var files = newSeq[string]()
    var dirs = newSeq[string]()
    for kind, path in walkDir(d):
      case kind
      of pcFile:
        if path.hasRightFileName(walkOptC):
          files.add(path)
      of pcLinkToFile:
        if optFollow in options and path.hasRightFileName(walkOptC):
          files.add(path)
      of pcDir:
        if optRecursive in options and path.hasRightDirectory(walkOptC):
          dirs.add path
      of pcLinkToDir:
        if optFollow in options and optRecursive in options and
           path.hasRightDirectory(walkOptC):
          dirs.add path
    if sortTime:  # sort by time - collect files before yielding
      for file in files:
        timeFiles.add((getLastModificationTime(file), file))
    else:  # alphanumeric sort, yield immediately after sorting
      files.sort()
      for file in files:
        yield file
      dirs.sort(order = SortOrder.Descending)
    for dir in dirs:
      dirStack.add(dir)
  if sortTime:
    timeFiles.sort(sortTimeOrder)
    for (_, file) in timeFiles:
      yield file

iterator walkRec(paths: seq[string]): (string, string) =
  declareCompiledPatterns(walkOptC, WalkOptComp):
    walkOptC.excludeFile.add walkOpt.excludeFile.compileArray()
    walkOptC.includeFile.add walkOpt.includeFile.compileArray()
    walkOptC.excludeDir.add  walkOpt.excludeDir.compileArray()
    for path in paths:
      if dirExists(path):
        for p in walkDirBasic(path, walkOptC):
          yield ("", p)
      elif fileExists(path):
        yield ("", path)
      else:
        yield ("Error: no such file or directory: ", path)

template printResult(filename: string, body: untyped) =
  var filenameShown = false
  template showFilename =
    if not filenameShown:
      printBlockFile(filename)
      stdout.write("\n")
      stdout.flushFile()
      filenameShown = true
  if optVerbose in options:
    showFilename
  for output in body:
    updateCounters(output)
    if output.kind notin {Rejected, OpenError, JustCount} and not oneline:
      showFilename
    if output.kind == JustCount and oneline:
      printFile(filename & ":")
    printOutput(filename, output)
  
proc replaceMatches(filename: string, buffer: string, outpSeq: seq[Output]) =
      var newBuf = newStringOfCap(buffer.len)

      var changed = false
      var lineRepl = 1
      let si: SearchInfo = (buf: buffer, filename: filename)
      var i = 0
      for output in outpSeq:
        if output.kind in {GroupFirstMatch, GroupNextMatch}:
          #let r = replace(curMi.match, pattern, replacement % matches) #TODO
          let curMi = output.match
          let r = replace(curMi.match, searchOpt.pattern, replacement)
          if replace1match(si, curMi, i, r, newBuf, lineRepl):
            changed = true
          i = curMi.last + 1
      if changed:
        newBuf.add(substr(buffer, i))  # finalize new buffer after last match
        var f: File
        if open(f, filename, fmWrite):
          f.write(newBuf)
          f.close()
        else:
          printError "cannot open file for overwriting: " & filename
          inc(gVar.errors)

proc run1Thread() =
  declareCompiledPatterns(searchOptC, SearchOptComp):
      searchOptC.pattern = searchOpt.pattern.compile()
      searchOptC.checkMatch = searchOpt.checkMatch.compile()
      searchOptC.checkNoMatch = searchOpt.checkNoMatch.compile()
      for (err, filename) in walkRec(paths):
        if err != "":
          inc(gVar.errors)
          printError (err & filename)
          continue
        if optReplace notin options:
            printResult(filename, processFile(searchOptC, filename))
        else:
          var matches = newSeq[Output]()
          var buffer = ""

          for output in processFile(searchOptC, filename, yieldContents=true):
            updateCounters(output)
            case output.kind
            of Rejected, OpenError, JustCount: discard
            of GroupFirstMatch, GroupNextMatch, GroupEnd: matches.add(output)
            of FileContents: buffer = output.buffer
          if matches.len > 0:
            replaceMatches(filename, buffer, matches)

# Multi-threaded version: all printing is being done in the Main thread.
# Totally nWorkers+1 additional threads are created (workers + pathProducer).
# An example of nWorkers=2:
#
#  ------------------  initial paths   -------------------
#  |  Main thread   |----------------->|  pathProducer   |
#  ------------------                  -------------------
#             ^                          |        | 
# resultsChan |                          |        | searchRequestsChan
#             |       number of files    |   -----+-----
#         ----+---------------------------   |         |
#         |   |   (when walking finished)    |a path   |a path to file
#         |   |                              |         |
#         |   |                              V         V 
#         |   |                      ------------  ------------
#         |   |                      | worker 1 |  | worker 2 |
#         |   |                      ------------  ------------
#         |   |  matches in the file         |         |
#         |   --------------------------------         |
#         |      matches in the file                   |
#         ----------------------------------------------

proc worker(initSearchOpt: SearchOpt) {.thread.} =
  searchOpt = initSearchOpt  # init thread-local var
  declareCompiledPatterns(searchOptC, SearchOptComp):
    searchOptC.pattern = searchOpt.pattern.compile()
    searchOptC.checkMatch = searchOpt.checkMatch.compile()
    searchOptC.checkNoMatch = searchOpt.checkNoMatch.compile()
    while true:
      let (fileNo, filename) = searchRequestsChan.recv()
      var fileResult = newSeq[Output]();
      for output in processFile(searchOptC, filename,
                                yieldContents=(optReplace in options)):
        fileResult.add(output)
      resultsChan.send((false, fileNo, filename, move(fileResult)))

proc pathProducer(arg: (seq[string], WalkOpt)) {.thread.} =
  let paths = arg[0]
  walkOpt = arg[1]  # init thread-local copy of opt
  var
    nextFileN = 0
  for (err, filename) in walkRec(paths):
    if err == "":
      searchRequestsChan.send((nextFileN,filename))
    else:
      resultsChan.send((false, nextFileN,
                        filename, @[Output(kind: OpenError, msg: err)]))
    nextFileN += 1
  resultsChan.send((true, nextFileN, "", @[]))

proc runMultiThread() =
  var
    workers = newSeq[Thread[SearchOpt]](nWorkers)
    storage = newTable[int, (string, seq[Output]) ]()
      # file number -> accumulated result
    firstUnprocessedFile = 0
  open(searchRequestsChan)
  open(resultsChan)
  for n in 0 ..< nWorkers:
    createThread(workers[n], worker, searchOpt)
  var producerThread: Thread[(seq[string], WalkOpt)]
  createThread(producerThread, pathProducer, (paths, walkOpt))
  template process1result(fileNo: int, fname: string, fileResult: seq[Output]) =
      storage[fileNo] = (fname, fileResult)
      var outpSeq: seq[Output]
      while storage.haskey(firstUnprocessedFile):
        outpSeq = storage[firstUnprocessedFile][1]
        let filename = storage[firstUnprocessedFile][0]
        if optReplace notin options:
          printResult(filename, outpSeq)
        else:
          var buffer = ""

          var matches = newSeq[Output]()
          for output in outpSeq:
            updateCounters(output)
            case output.kind
            of Rejected, OpenError, JustCount: discard
            # printError error
            of GroupFirstMatch, GroupNextMatch, GroupEnd: matches.add(output)
            of FileContents: buffer = output.buffer
          if matches.len > 0:
            replaceMatches(filename, buffer, matches)
        storage.del(firstUnprocessedFile)
        firstUnprocessedFile += 1
  var totalFiles = -1  # will be known when pathProducer finishes
  while totalFiles == -1 or firstUnprocessedFile < totalFiles:
    let msg = resultsChan.recv()
    if msg.finished:
      totalFiles = msg.fileNo
    else:
      process1result(msg.fileNo, msg.filename, msg.fileResult)

proc run() =
  if nWorkers == 0:
    run1Thread()
  else:
    runMultiThread()

proc reportError(msg: string) =
  printError "Error: " & msg
  quit "Run nimgrep --help for the list of options"

proc writeHelp() =
  stdout.write(Usage)
  stdout.flushFile()
  quit(0)

proc writeVersion() =
  stdout.write(Version & "\n")
  stdout.flushFile()
  quit(0)

proc checkOptions(subset: TOptions, a, b: string) =
  if subset <= options:
    quit("cannot specify both '$#' and '$#'" % [a, b])

when defined(posix):
  useWriteStyled = terminal.isatty(stdout)
  # that should be before option processing to allow override of useWriteStyled

for kind, key, val in getopt():
  case kind
  of cmdArgument:
    if options.contains(optStdin):
      paths.add(key)
    elif searchOpt.pattern.len == 0:
      searchOpt.pattern = key
    elif options.contains(optReplace) and replacement.len == 0:
      replacement = key
    else:
      paths.add(key)
  of cmdLongOption, cmdShortOption:
    case normalize(key)
    of "find", "f": incl(options, optFind)
    of "replace", "!": incl(options, optReplace)
    of "peg":
      excl(options, optRegex)
      incl(options, optPeg)
    of "re":
      incl(options, optRegex)
      excl(options, optPeg)
    of "rex", "x":
      incl(options, optRex)
      incl(options, optRegex)
      excl(options, optPeg)
    of "recursive", "r": incl(options, optRecursive)
    of "follow": incl(options, optFollow)
    of "confirm": incl(options, optConfirm)
    of "stdin": incl(options, optStdin)
    of "word", "w": incl(options, optWord)
    of "ignorecase", "ignore-case", "i": incl(options, optIgnoreCase)
    of "ignorestyle", "ignore-style", "y": incl(options, optIgnoreStyle)
    of "nworkers", "n":
      if val == "":
        nWorkers = countProcessors()
      else:
        nWorkers = parseInt(val)
    of "ext": walkOpt.extensions.add val.split('|')
    of "noext", "no-ext": walkOpt.skipExtensions.add val.split('|')
    of "excludedir", "exclude-dir": walkOpt.excludeDir.add val
    of "includefile", "include-file": walkOpt.includeFile.add val
    of "excludefile", "exclude-file": walkOpt.excludeFile.add val
    of "match", "m": searchOpt.checkMatch = val
    of "nomatch", "notmatch", "not-match", "no-match":
      searchOpt.checkNoMatch = val
    of "bin":
      case val
      of "no": searchOpt.checkBin = biNo
      of "yes": searchOpt.checkBin = biYes
      of "only": searchOpt.checkBin = biOnly
      else: reportError("unknown value for --bin")
    of "text", "t": searchOpt.checkBin = biNo
    of "count": justCount = true
    of "sorttime", "sort-time", "s":
      sortTime = true
      case normalize(val)
      of "": discard
      of "asc", "ascending": sortTimeOrder = SortOrder.Ascending
      of "desc", "descending": sortTimeOrder = SortOrder.Descending
      else: reportError("invalid value '" & val & "' for --sortTime")
    of "nocolor", "no-color": useWriteStyled = false
    of "color":
      case val
      of "auto": discard
      of "never", "false": useWriteStyled = false
      of "", "always", "true": useWriteStyled = true
      else: reportError("invalid value '" & val & "' for --color")
    of "colortheme", "color-theme":
      colortheme = normalize(val)
      if colortheme notin ["simple", "bnw", "ack", "gnu"]:
        reportError("unknown colortheme '" & val & "'")
    of "beforecontext", "before-context", "b":
      try:
        linesBefore = parseInt(val)
      except ValueError:
        reportError("option " & key & " requires an integer but '" &
                    val & "' was given")
    of "aftercontext", "after-context", "a":
      try:
        linesAfter = parseInt(val)
      except ValueError:
        reportError("option " & key & " requires an integer but '" &
                    val & "' was given")
    of "context", "c":
      try:
        linesContext = parseInt(val)
      except ValueError:
        reportError("option --context requires an integer but '" &
                    val & "' was given")
    of "newline", "l": newLine = true
    of "oneline": oneline = true
    of "group", "g": oneline = false
    of "verbose": incl(options, optVerbose)
    of "filenames": incl(options, optFilenames)
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
    else: reportError("unrecognized option '" & key & "'")
  of cmdEnd: assert(false) # cannot happen

checkOptions({optFind, optReplace}, "find", "replace")
checkOptions({optPeg, optRegex}, "peg", "re")
checkOptions({optIgnoreCase, optIgnoreStyle}, "ignore_case", "ignore_style")
checkOptions({optFilenames, optReplace}, "filenames", "replace")

linesBefore = max(linesBefore, linesContext)
linesAfter  = max(linesAfter,  linesContext)

if optStdin in options:
  searchOpt.pattern = ask("pattern [ENTER to exit]: ")
  if searchOpt.pattern.len == 0: quit(0)
  if optReplace in options:
    replacement = ask("replacement [supports $1, $# notations]: ")

if searchOpt.pattern.len == 0:
  reportError("empty pattern was given")
else:
  if paths.len == 0:
    paths.add(os.getCurrentDir())
  run()
  if gVar.errors != 0:
    printError $gVar.errors & " errors"
  stdout.write($gVar.matches & " matches\n")
  if gVar.errors != 0:
    quit(1)
