#
#
#           Nim Grep Utility
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, parseopt, pegs, re, terminal, osproc, tables

const
  Version = "1.5"
  Usage = "nimgrep - Nim Grep Utility Version " & Version & """

  (c) 2012 Andreas Rumpf
Usage:
  nimgrep [options] [pattern] [replacement] (file/directory)*
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
  --includeFile:PAT   include only files whose names match the given regex PAT
  --excludeFile:PAT   skip files whose names match the given regex pattern PAT
  --excludeDir:PAT    skip directories whose names match the given regex PAT
  --bin:yes|no|only   process binary files? (detected by first 1024 bytes)
  --text, -t          process only text, the same as --bin:no
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

using pattern: Pattern

var
  paths: seq[string] = @[]
  pattern = ""
  replacement = ""
  extensions: seq[string] = @[]
  options: TOptions = {optRegex}
  skipExtensions: seq[string] = @[]
  excludeFile: seq[Regex]
  includeFile: seq[Regex]
  excludeDir: seq[Regex]
  checkBin = biYes
  justCount = false
  useWriteStyled = true
  oneline = true
  linesBefore = 0
  linesAfter = 0
  linesContext = 0
  colorTheme = "simple"
  newLine = false
  gVar = (matches: 0, errors: 0, reallyReplace: false)
    # gVar - variables that can change during search/replace
  nWorkers = 0  # run in single thread by default
  requests: Channel[(int, string)]
  results: Channel[tuple[fileNo: int, result: seq[Output]]]

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
  elif newLine:
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
  if not newLine:
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
      printError("can not open file " & filename)
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

iterator searchFile(pattern; filename: string; buffer: string): Output =
  let si: SearchInfo = (buf: buffer, filename: filename)
  var prevMi, curMi: MatchInfo
  curMi.lineEnd = 1
  var i = 0
  var matches: array[0..re.MaxSubpatterns-1, string]
  for j in 0..high(matches): matches[j] = ""
  while i < buffer.len:
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
    if prevMi.lineBeg == 0: # no previous match, so no previous block to finalize
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
      #if t.last == buffer.len - 1:  # TODO
      #  stdout.write("\n")
      #stdout.flushFile()

    i = t.last+1
    prevMi = curMi

func detectBin(buffer: string): bool =
  for i in 0 ..< min(1024, buffer.len):
    if buffer[i] == '\0':
      return true

iterator processFile(pattern; filename: string, yieldContents=false): Output =
  var buffer: string

  if optFilenames in options:
    buffer = filename
  else:
    try:
      buffer = system.readFile(filename)
    except IOError:
      yield Output(kind: OpenError)

  var reject = false
  if checkBin in {biNo, biOnly}:
    let isBin = detectBin(buffer)
    if isBin and checkBin == biNo:
      reject = true
    if (not isBin) and checkBin == biOnly:
      reject = true

  if reject:
    yield Output(kind: Rejected)
  else:
    var found = false
    var cnt = 0
    for output in searchFile(pattern, filename, buffer):
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

proc hasRightFileName(path: string): bool =
  let filename = path.lastPathPart
  let ex = filename.splitFile.ext.substr(1) # skip leading '.'
  if extensions.len != 0:
    var matched = false
    for x in items(extensions):
      if os.cmpPaths(x, ex) == 0:
        matched = true
        break
    if not matched: return false
  for x in items(skipExtensions):
    if os.cmpPaths(x, ex) == 0: return false
  if includeFile.len != 0:
    var matched = false
    for x in items(includeFile):
      if filename.match(x):
        matched = true
        break
    if not matched: return false
  for x in items(excludeFile):
    if filename.match(x): return false
  result = true

proc hasRightDirectory(path: string): bool =
  let dirname = path.lastPathPart
  for x in items(excludeDir):
    if dirname.match(x): return false
  result = true

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

proc walker(dir: string; files: var seq[string]) =
  if dirExists(dir):
    for kind, path in walkDir(dir):
      case kind
      of pcFile:
        if path.hasRightFileName:
          files.add(path)
      of pcLinkToFile:
        if optFollow in options and path.hasRightFileName:
          files.add(path)
      of pcDir:
        if optRecursive in options and path.hasRightDirectory:
          walker(path, files)
      of pcLinkToDir:
        if optFollow in options and optRecursive in options and
           path.hasRightDirectory:
          walker(path, files)
  elif fileExists(dir):
    files.add(dir)
  else:
    printError "Error: no such file or directory: " & dir
    inc(gVar.errors)

iterator walkDirBasic(dir: string): string =
  var dirs = @[dir]  # stack of directories
  while dirs.len > 0:
    let d = dirs.pop()
    for kind, path in walkDir(d):
      case kind
      of pcFile:
        if path.hasRightFileName:
          yield path
      of pcLinkToFile:
        if optFollow in options and path.hasRightFileName:
          yield path
      of pcDir:
        if optRecursive in options and path.hasRightDirectory:
          dirs.add path
      of pcLinkToDir:
        if optFollow in options and optRecursive in options and
           path.hasRightDirectory:
          dirs.add path

iterator walkRec(paths: seq[string]): string =
  for path in paths:
    if existsDir(path):
      for p in walkDirBasic(path):
        yield p
    elif existsFile(path):
      yield path
    else:
      printError "Error: no such file or directory: " & path
      inc(gVar.errors)

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
  
proc worker(pattern: Pattern) {.thread.} =
  while true:
    let (fileNo, filename) = requests.recv()
    var rslt = newSeq[Output]();
    for output in processFile(pattern, filename, yieldContents=(optReplace in options)):
      rslt.add(output)
    results.send((fileNo, move(rslt)))
    
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
          let r = replace(curMi.match, pattern, replacement)
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

proc runMultiThread(pattern) =
    stdout.flushFile()
    var
      workers = newSeq[Thread[Pattern]](nWorkers)
    open(requests)
    open(results)
    for n in 0 ..< nWorkers:
      createThread(workers[n], worker, pattern)
    var
      inWork = 0
      nextFile = 0
      firstFile = 0
      storage = newTable[int, seq[Output]]() # file number -> accumulated result
      files = newTable[int, string]()
    template proc1result(fileNo, newOutpSeq) =
        storage[fileNo] = newOutpSeq
        var outpSeq: seq[Output]
        while storage.haskey(firstFile):
          outpSeq = storage[firstFile]
          let filename = files[firstFile]
          if optReplace notin options:
            printResult(filename, outpSeq)
          else:
            var buffer = ""

            var matches = newSeq[Output]()
            for output in outpSeq:
              updateCounters(output)
              case output.kind
              of Rejected, OpenError, JustCount: discard
              of GroupFirstMatch, GroupNextMatch, GroupEnd: matches.add(output)
              of FileContents: buffer = output.buffer
            if matches.len > 0:
              replaceMatches(filename, buffer, matches)
          firstFile += 1
    for filename in walkRec(paths):
      requests.send((nextFile,filename))
      files[nextFile] = filename
      nextFile += 1
      inWork += 1
      let (available, msg) = results.tryRecv()
      if available:
        proc1result(msg.fileNo, msg.result)
        inWork -= 1
    while inWork > 0:
      let (fileNo, newOutpSeq) = results.recv()
      proc1result(fileNo, newOutpSeq)
      inWork -= 1

proc run1Thread(pattern) =
  for filename in walkRec(paths):
    if optReplace notin options:
      printResult(filename, processFile(pattern, filename))
    else:
      var matches = newSeq[Output]()
      var buffer = ""

      for output in processFile(pattern, filename, yieldContents=true):
        updateCounters(output)
        case output.kind
        of Rejected, OpenError, JustCount: discard
        of GroupFirstMatch, GroupNextMatch, GroupEnd: matches.add(output)
        of FileContents: buffer = output.buffer
      if matches.len > 0:
        replaceMatches(filename, buffer, matches)

proc run(pattern) =
  if nWorkers == 0:
    run1Thread(pattern)
  else:
    runMultiThread(pattern)

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
    elif pattern.len == 0:
      pattern = key
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
    of "ignorecase", "i": incl(options, optIgnoreCase)
    of "ignorestyle", "y": incl(options, optIgnoreStyle)
    of "nworkers", "n":
      if val == "":
        nWorkers = countProcessors()
      else:
        nWorkers = parseInt(val)
    of "ext": extensions.add val.split('|')
    of "noext": skipExtensions.add val.split('|')
    of "excludedir", "exclude-dir": excludeDir.add rex(val)
    of "includefile", "include-file": includeFile.add rex(val)
    of "excludefile", "exclude-file": excludeFile.add rex(val)
    of "bin":
      case val
      of "no": checkBin = biNo
      of "yes": checkBin = biYes
      of "only": checkBin = biOnly
      else: reportError("unknown value for --bin")
    of "text", "t": checkBin = biNo
    of "count": justCount = true
    of "nocolor": useWriteStyled = false
    of "color":
      case val
      of "auto": discard
      of "never", "false": useWriteStyled = false
      of "", "always", "true": useWriteStyled = true
      else: reportError("invalid value '" & val & "' for --color")
    of "colortheme":
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
  pattern = ask("pattern [ENTER to exit]: ")
  if pattern.len == 0: quit(0)
  if optReplace in options:
    replacement = ask("replacement [supports $1, $# notations]: ")

if pattern.len == 0:
  reportError("empty pattern was given")
else:
  if paths.len == 0:
    paths.add(os.getCurrentDir())
  if optRegex notin options:
    if optWord in options:
      pattern = r"(^ / !\letter)(" & pattern & r") !\letter"
    if optIgnoreStyle in options:
      pattern = "\\y " & pattern
    elif optIgnoreCase in options:
      pattern = "\\i " & pattern
    let pegp = peg(pattern)
    run(pegp)
  else:
    var reflags = {reStudy}
    if optIgnoreStyle in options:
      pattern = styleInsensitive(pattern)
    if optWord in options:
      # see https://github.com/nim-lang/Nim/issues/13528#issuecomment-592786443
      pattern = r"(^|\W)(:?" & pattern & r")($|\W)"
    if {optIgnoreCase, optIgnoreStyle} * options != {}:
      reflags.incl reIgnoreCase
    let rep = if optRex in options: rex(pattern, reflags)
              else: re(pattern, reflags)
    run(rep)
  if gVar.errors != 0:
    printError $gVar.errors & " errors"
  stdout.write($gVar.matches & " matches\n")
  if gVar.errors != 0:
    quit(1)
