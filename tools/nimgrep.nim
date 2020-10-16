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
  --includeFile:PAT   search only files whose names match the given PATttern
  --excludeFile:PAT   skip files whose names match the given pattern PAT
  --includeDir:PAT    search only files with full directory name matching PAT
  --excludeDir:PAT    skip directories whose names match the given pattern PAT
  --if,--ef,--id,--ed abbreviations of 4 options above
  --match:PAT         select files containing a (not displayed) match of PAT
  --noMatch:PAT       select files not containing any match of PAT
  --bin:yes|no|only   process binary files? (detected by \0 in first 1K bytes)
  --text, -t          process only text files, the same as --bin:no
  --count             only print counts of matches for files that matched
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
       -s[:asc|desc]  - ascending (default: recent files go last) or descending
  --group, -g         group matches by file
  --newLine, -l       display every matching line starting from a new line
  --limit[:N], -m[:N] limit max width of lines from files by N characters (80)
  --fit               calculate --limit from terminal width for every line
  --onlyAscii, -o     use only printable ASCII Latin characters 0x20-0x7E
                      (substitutions: 0 -> @, 1-0x1F -> A-_, 0x7F-0xFF -> !)
  --verbose           be verbose: list every processed file
  --filenames         find the pattern in the filenames, not in the contents
                      of the file
  --help, -h          shows this help
  --version, -v       shows the version
"""

# Search results for a file are modelled by these levels:
# FileResult -> Block -> Output/Chunk -> SubLine
#
# 1. SubLine is an entire line or its part.
#
# 2. Chunk, which is a sequence of SubLine, represents a match and its
#    surrounding context.
#    Output is a Chunk or one of auxiliary results like an OpenError.
#
# 3. Block, which is a sequence of Chunks, is not present as a separate type.
#    It will just be separated from another Block by newline when there is
#    more than 3 lines in it.
#    Here is an example of a Block where only 1 match is found and
#    1 line before and 1 line after of context are required:
#
#     ...a_line_before...................................... <<<SubLine(Chunk 1)
#
#     .......pre.......  ....new_match....  .......post......
#     ^^^^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^^  ^^^^^^^^^^^^^^^^^
#     SubLine (Chunk 1)  SubLine (Chunk 1)  SubLine (Chunk 2)
#
#     ...a_line_after....................................... <<<SubLine(Chunk 2)
#
# 4. FileResult is printed as a sequence of Blocks.
#    However FileResult is represented as seq[Output] in the program.

type
  TOption = enum
    optFind, optReplace, optPeg, optRegex, optRecursive, optConfirm, optStdin,
    optWord, optIgnoreCase, optIgnoreStyle, optVerbose, optFilenames,
    optRex, optFollow, optLimitChars, optFit
  TOptions = set[TOption]
  TConfirmEnum = enum
    ceAbort, ceYes, ceAll, ceNo, ceNone
  Bin = enum
    biYes, biOnly, biNo
  Pattern = Regex | Peg
  MatchInfo = tuple[first: int, last: int;
                    lineBeg: int, lineEnd: int, match: string]
  outputKind = enum
    OpenError, Rejected, JustCount,
    BlockFirstMatch, BlockNextMatch, BlockEnd, FileContents
  Output = object
    case kind: outputKind
    of OpenError: msg: string
    of Rejected: reason: string
    of JustCount: matches: int
    of BlockFirstMatch, BlockNextMatch:
      pre: string
      match: MatchInfo
    of BlockEnd:
      blockEnding: string
      firstLine: int       # = last lineNo of last match
    of FileContents:
      buffer: string
  Trequest = (int, string)
  FileResult = seq[Output]
  Tresult = tuple[finished: bool, fileNo: int,
                  filename: string, fileResult: FileResult]
  WalkOpt = tuple  # used for walking directories/producing paths
    extensions: seq[string]
    skipExtensions: seq[string]
    excludeFile: seq[string]
    includeFile: seq[string]
    includeDir : seq[string]
    excludeDir : seq[string]
  WalkOptComp[Pat] = tuple  # a compiled version of the previous
    excludeFile: seq[Pat]
    includeFile: seq[Pat]
    includeDir : seq[Pat]
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
  SinglePattern[PAT] = tuple  # compile single pattern for replacef
    pattern: PAT

var
  paths: seq[string] = @[]
  replacement = ""
  options: TOptions = {optRegex}
  walkOpt {.threadvar.}: WalkOpt
  searchOpt {.threadvar.}: SearchOpt
  justCount = false
  sortTime = false
  sortTimeOrder = SortOrder.Ascending
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
  limitChar = high(int)  # don't limit line width by default
  optOnlyAscii: bool

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

proc printBold(s: string) =
  whenColors:
    stdout.styledWrite(styleBright, s)

proc printSpecial(s: string) =
  whenColors:
    case colorTheme
    of "simple", "bnw": stdout.styledWrite(styleBright, s)
    of "ack", "gnu": stdout.styledWrite(styleReverse, fgBlue, bgDefault, s)

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

type Column = tuple  # current column info for the cropping (--limit) feature
  terminal: int
  file: int
  overflowMatches: int

proc newLn(curCol: var Column) =
  stdout.write("\n")
  curCol.file = 0
  curcol.terminal = 0

proc lineHeader(filename: string, line: int|string, isMatch: bool, curCol: var Column) =
  let lineSym =
    if isMatch: $line & ":"
    else: $line & " "
  if not newLine and optFilenames notin options:
    if oneline:
      printFile(filename)
      printLineN(":" & lineSym, isMatch)
      curcol.terminal += filename.len + 1 + lineSym.len
    else:
      printLineN(lineSym.align(alignment+1), isMatch)
      curcol.terminal += lineSym.align(alignment+1).len
    stdout.write(" "); curCol.terminal += 1

proc printMatch(fileName: string, mi: MatchInfo, curCol: var Column) =
  let sLines = mi.match.splitLines()
  for i, l in sLines:
    if i > 0:
      lineHeader(filename, mi.lineBeg + i, isMatch = true, curCol)
    if curCol.terminal < limitChar:
      writeColored(l)
    else:
      curCol.overflowMatches += 1
    if i < sLines.len - 1:
      newLn(curCol)
  curCol.terminal += mi.match.len
  curCol.file += mi.match.len

const matchPaddingFromRight = 10
let ellipsis = "..."

proc reserveChars(mi: MatchInfo): int =
  if optLimitChars in options or optFit in options:
    let patternChars = afterPattern(mi.match, 0) + 1
    result = patternChars + ellipsis.len + matchPaddingFromRight
  else:
    result = 0

proc printRaw(c: char, curCol: var Column, allowTabs = true) =
  # print taking into account tabs and optOnlyAscii
  if c == '\t':
    if allowTabs:
      let spaces = 8 - (curCol.file mod 8)
      curCol.file += spaces
      curCol.terminal += spaces
      if optOnlyAscii:
        printSpecial " "
        stdout.write " ".repeat(spaces-1)
      else:
        stdout.write " ".repeat(spaces)
    else:
      curCol.file += 1
      curCol.terminal += 1
      if optOnlyAscii:
        printSpecial " "
      else:
        stdout.write " "
  elif not optOnlyAscii or (0x20 <= int(c) and int(c) <= 0x7e):
    stdout.write c
    curCol.file += 1
    curCol.terminal += 1
  else:  # substitute characters that are not ACSII Latin
    let substitute =
      if int(c) < 0x20:
        char(int(c) + 0x40)  # use common "control codes"
      else: '!'
    printSpecial $substitute
    curCol.file += 1
    curCol.terminal += 1

proc calcTabLen(s: string, chars: int, fromLeft: bool): int =
  if chars < 0:
    return 0
  var col = 0
  var first, last: int
  if fromLeft:
    first = max(0, s.len - chars)
    last = s.len - 1
  else:
    first = 0
    last = min(s.len - 1, chars - 1)
  for c in s[first .. last]:
    if c == '\t':
      result += 8 - (col mod 8) - 1
      col += 8 - (col mod 8)

proc printCropped(s: string, curCol: var Column, fromLeft: bool) =
  let eL = ellipsis.len
  let charsAllowed = limitChar - curCol.terminal
  let tabLen = calcTabLen(s, charsAllowed, fromLeft)
  if s.len + tabLen <= charsAllowed:
    for c in s:
      printRaw(c, curCol)
  elif charsAllowed <= eL:
    if curCol.overflowMatches == 0:
      printBold ellipsis
      curCol.terminal += eL
  else:
    if fromLeft:
      printBold ellipsis
      curCol.terminal += 3
      # don't expand tabs when cropped from left
      let first = max(0, s.len - (charsAllowed - eL))
      for c in s[first .. s.len - 1]:
        printRaw(c, curCol, allowTabs=false)
    else:
      let last = min(s.len - 1, charsAllowed - eL - 1)
      for c in s[0 .. last]:
        printRaw(c, curCol, allowTabs=true)
        if curCol.terminal >= limitChar - eL:
          break
      printBold ellipsis
      curCol.terminal += 3

proc getSubLinesBefore(buf: string, curMi: MatchInfo): string =
  let first = beforePattern(buf, curMi.first-1, linesBefore+1)
  result = substr(buf, first, curMi.first-1)

proc printSubLinesBefore(filename: string, beforeMatch: string, lineBeg: int,
                         curCol: var Column, reserveChars: int, replMode=false) =
  # start block: print 'linesBefore' lines before current match `curMi`
  let sLines = splitLines(beforeMatch)
  let startLine = lineBeg - sLines.len + 1
  blockHeader(filename, lineBeg, replMode=replMode)
  for i, l in sLines:
    let isLastLine = i == sLines.len - 1
    lineHeader(filename, startLine + i, isMatch = isLastLine, curCol)
    if isLastLine: limitChar -= reserveChars
    l.printCropped(curCol, fromLeft = isLastLine)
    if isLastLine: limitChar += reserveChars
    if not isLastLine:
      newLn(curCol)

proc getSubLinesAfter(buf: string, mi: MatchInfo): string =
  let last = afterPattern(buf, mi.last+1, 1+linesAfter)
  result = substr(buf, mi.last+1, last)

proc printOverflow(filename: string, line: int, curCol: var Column) =
  if curCol.overflowMatches > 0:
    lineHeader(filename, line, isMatch = true, curCol)
    printBold("(" & $curCol.overflowMatches & " more matches skipped)")
    newLn(curCol)
    curCol.overflowMatches = 0

proc printSubLinesAfter(filename: string, afterMatch: string, matchLineEnd: int,
                        curCol: var Column) =
  # finish block: print 'linesAfter' lines after match `mi`
  let sLines = splitLines(afterMatch)
  if sLines.len == 0: # EOF
    newLn(curCol)
  else:
    sLines[0].printCropped(curCol, fromLeft = false)
      # complete the line after the match itself
    newLn(curCol)
    printOverflow(filename, matchLineEnd, curCol)
    #let skipLine =  # workaround posix line ending at the end of file
    #  if last == s.len-1 and s.len >= 2 and s[^1] == '\l' and s[^2] != '\c': 1
    #  else: 0  TODO:
    let skipLine = 0
    for i in 1 ..< sLines.len - skipLine:
      lineHeader(filename, matchLineEnd + i, isMatch = false, curCol)
      sLines[i].printCropped(curCol, fromLeft = false)
      newLn(curCol)

proc getSubLinesBetween(buf: string, prevMi: MatchInfo,
                        curMi: MatchInfo): string =
  buf.substr(prevMi.last+1, curMi.first-1)

proc printBetweenMatches(filename: string, betweenMatches: string,
                         lastLineBeg: int,
                         curCol: var Column, reserveChars: int) =
  # continue block: print between `prevMi` and `curMi`
  let sLines = betweenMatches.splitLines()
  sLines[0].printCropped(curCol, fromLeft = false)
    # finish the line of previous Match
  if sLines.len > 1:
    newLn(curCol)
    printOverflow(filename, lastLineBeg - sLines.len + 1, curCol)
    for i in 1 ..< sLines.len:
      let isLastLine = i == sLines.len - 1
      lineHeader(filename, lastLineBeg - sLines.len + i + 1,
                 isMatch = isLastLine, curCol)
      if isLastLine: limitChar -= reserveChars
      sLines[i].printCropped(curCol, fromLeft = isLastLine)
      if isLastLine: limitChar += reserveChars
      if not isLastLine:
        newLn(curCol)

proc printReplacement(filename: string, buf: string, mi: MatchInfo,
                      repl: string, showRepl: bool, curPos: int,
                      newBuf: string, curLine: int) =
  let filename = fileName
  var curCol: Column
  printSubLinesBefore(fileName, getSubLinesBefore(buf, mi), mi.lineBeg,
                      curCol, reserveChars(mi))
  printMatch(fileName, mi, curCol)
  printSubLinesAfter(fileName, getSubLinesAfter(buf, mi), mi.lineEnd, curCol)
  stdout.flushFile()
  if showRepl:
    let miForNewBuf: MatchInfo =
      (first: newBuf.len, last: newBuf.len,
       lineBeg: curLine, lineEnd: curLine, match: "")
    printSubLinesBefore(fileName, getSubLinesBefore(newBuf, miForNewBuf),
                        miForNewBuf.lineBeg, curCol, reserveChars(miForNewBuf),
                        replMode=true)

    let replLines = countLineBreaks(repl, 0, repl.len-1)
    let miFixLines: MatchInfo =
      (first: mi.first, last: mi.last,
       lineBeg: curLine, lineEnd: curLine + replLines, match: repl)
    printMatch(fileName, miFixLines, curCol)
    printSubLinesAfter(fileName, getSubLinesAfter(buf, miFixLines),
                       miFixLines.lineEnd, curCol)
    stdout.flushFile()

proc replace1match(filename: string, buf: string, mi: MatchInfo, i: int,
                   r: string; newBuf: var string, curLine: var int): bool =
  newBuf.add(buf.substr(i, mi.first-1))
  inc(curLine, countLineBreaks(buf, i, mi.first-1))
  if optConfirm in options:
    printReplacement(filename, buf, mi, r, showRepl=true, i, newBuf, curLine)
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
    printReplacement(filename, buf, mi, r, showRepl=gVar.reallyReplace, i,
                     newBuf, curLine)
  if gVar.reallyReplace:
    result = true
    newBuf.add(r)
    inc(curLine, countLineBreaks(r, 0, r.len-1))
  else:
    newBuf.add(mi.match)
    inc(curLine, countLineBreaks(mi.match, 0, mi.match.len-1))

template updateCounters(output: Output) =
  case output.kind
  of BlockFirstMatch, BlockNextMatch: inc(gVar.matches)
  of JustCount: inc(gVar.matches, output.matches)
  of OpenError: inc(gVar.errors)
  of Rejected, BlockEnd, FileContents: discard

proc printInfo(filename:string, output: Output) =
  case output.kind
  of OpenError:
    printError("can not open path " & filename & " " & output.msg)
  of Rejected:
    if optVerbose in options:
      echo "(rejected: ", output.reason, ")"
  of JustCount:
    echo " (" & $output.matches & " matches)"
  else: discard  # impossible

proc printOutput(filename: string, output: Output, curCol: var Column) =
  case output.kind
  of OpenError, Rejected, JustCount: printInfo(filename, output)
  of FileContents: discard # impossible
  of BlockFirstMatch:
    printSubLinesBefore(filename, output.pre, output.match.lineBeg,
                        curCol, reserveChars(output.match))
    printMatch(filename, output.match, curCol)
    #flush: TODO
  of BlockNextMatch:
    printBetweenMatches(filename, output.pre, output.match.lineBeg,
                        curCol, reserveChars(output.match))
    printMatch(filename, output.match, curCol)
  of BlockEnd:
    printSubLinesAfter(filename, output.blockEnding, output.firstLine, curCol)
    if linesAfter + linesBefore >= 2 and not newLine: stdout.write("\n")

iterator searchFile(pattern: Pattern; filename: string;
                    buffer: string): Output =
  var prevMi, curMi: MatchInfo
  curMi.lineEnd = 1
  var i = 0
  var matches: array[0..re.MaxSubpatterns-1, string]
  for j in 0..high(matches): matches[j] = ""
  while true:
    let t = findBounds(buffer, pattern, matches, i)
    if t.first < 0 or t.last < t.first:
      if prevMi.lineBeg != 0: # finalize last match
        yield Output(kind: BlockEnd,
                     blockEnding: getSubLinesAfter(buffer, prevMi),
                     firstLine: prevMi.lineEnd)
      break

    let lineBeg = curMi.lineEnd + countLineBreaks(buffer, i, t.first-1)
    curMi = (first: t.first,
             last: t.last,
             lineBeg: lineBeg,
             lineEnd: lineBeg + countLineBreaks(buffer, t.first, t.last),
             match: buffer.substr(t.first, t.last))
    if prevMi.lineBeg == 0: # no prev. match, so no prev. block to finalize
      yield Output(kind: BlockFirstMatch,
                   pre: getSubLinesBefore(buffer, curMi),
                   match: curMi)
    else:
      let nLinesBetween = curMi.lineBeg - prevMi.lineEnd
      if nLinesBetween <= linesAfter + linesBefore + 1: # print as 1 block
        yield Output(kind: BlockNextMatch,
                     pre: getSubLinesBetween(buffer, prevMi, curMi),
                     match: curMi)
      else: # finalize previous block and then print next block
        yield Output(kind: BlockEnd,
                     blockEnding: getSubLinesAfter(buffer, prevMi),
                     firstLine: prevMi.lineEnd)
        yield Output(kind: BlockFirstMatch,
                     pre: getSubLinesBefore(buffer, curMi),
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
  {.hint[XDeclaredButNotUsed]: off.}
  if optRegex notin options:
    var compiledStruct: StructType[Peg]
    template compile1Pattern(p: string, pat: Peg) =
      if p!="": pat = p.compilePeg()
    proc compileArray(initPattern: seq[string]): seq[Peg] =
      for pat in initPattern:
        result.add pat.compilePeg()
    body
  else:
    var compiledStruct: StructType[Regex]
    template compile1Pattern(p: string, pat: Regex) =
      if p!="": pat = p.compileRegex()
    proc compileArray(initPattern: seq[string]): seq[Regex] =
      for pat in initPattern:
        result.add pat.compileRegex()
    body
  {.hint[XDeclaredButNotUsed]: on.}

iterator processFile(searchOptC: SearchOptComp[Pattern], filename: string,
                     yieldContents=false): Output =
  var buffer: string

  if optFilenames in options:
    buffer = filename
  else:
    try:
      buffer = system.readFile(filename)
    except IOError as e:
      yield Output(kind: OpenError, msg: "readFile failed")

  var reject = false
  var reason: string
  if searchOpt.checkBin in {biNo, biOnly}:
    let isBin = detectBin(buffer)
    if isBin and searchOpt.checkBin == biNo:
      reject = true
      reason = "binary file"
    if (not isBin) and searchOpt.checkBin == biOnly:
      reject = true
      reason = "text file"

  if not reject:
    if searchOpt.checkMatch != "":
      reject = not contains(buffer, searchOptC.checkMatch, 0)
      reason = "doesn't contain a requested match"

  if not reject:
    if searchOpt.checkNoMatch != "":
      reject = contains(buffer, searchOptC.checkNoMatch, 0)
      reason = "contains a forbidden match"

  if reject:
    yield Output(kind: Rejected, reason: reason)
  else:
    var found = false
    var cnt = 0
    for output in searchFile(searchOptC.pattern, filename, buffer):
      found = true
      if not justCount:
        yield output
      else:
        if output.kind in {BlockFirstMatch, BlockNextMatch}:
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
  let dirname = path.parentDir
  if walkOptC.includeDir.len != 0:
    var matched = false
    for pat in walkOptC.includeDir:
      if dirname.match(pat):
        matched = true
        break
    if not matched: return false
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
        var time: Time
        try:
          time = getLastModificationTime(file)  # can fail for broken symlink
        except:
          discard
        timeFiles.add((time, file))
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
    walkOptC.includeDir.add  walkOpt.includeDir.compileArray()
    walkOptC.excludeDir.add  walkOpt.excludeDir.compileArray()
    for path in paths:
      if dirExists(path):
        for p in walkDirBasic(path, walkOptC):
          yield ("", p)
      elif fileExists(path):
        yield ("", path)
      else:
        yield ("Error: no such file or directory: ", path)

proc replaceMatches(pattern: Pattern; filename: string, buffer: string,
                    fileResult: FileResult) =
  var newBuf = newStringOfCap(buffer.len)

  var changed = false
  var lineRepl = 1
  var i = 0
  for output in fileResult:
    if output.kind in {BlockFirstMatch, BlockNextMatch}:
      let curMi = output.match
      let r = replacef(curMi.match, pattern, replacement)
      if replace1match(filename, buffer, curMi, i, r, newBuf, lineRepl):
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

template processFileResult(pattern: Pattern; filename: string,
                           fileResult: untyped) =
  var filenameShown = false
  template showFilename =
    if not filenameShown:
      printBlockFile(filename)
      stdout.write("\n")
      stdout.flushFile()
      filenameShown = true
  if optVerbose in options:
    showFilename
  if optReplace notin options:
    var curCol: Column
    for output in fileResult:
      updateCounters(output)
      if output.kind notin {Rejected, OpenError, JustCount} and not oneline:
        showFilename
      if output.kind == JustCount and oneline:
        printFile(filename & ":")
      printOutput(filename, output, curCol)
  else:
    var buffer = ""
    var matches: FileResult
    for output in fileResult:
      updateCounters(output)
      case output.kind
      of Rejected, OpenError, JustCount: printInfo(filename, output)
      of BlockFirstMatch, BlockNextMatch, BlockEnd:
        matches.add(output)
      of FileContents: buffer = output.buffer
    if matches.len > 0:
      replaceMatches(pattern, filename, buffer, matches)

proc run1Thread() =
  declareCompiledPatterns(searchOptC, SearchOptComp):
    compile1Pattern(searchOpt.pattern, searchOptC.pattern)
    compile1Pattern(searchOpt.checkMatch, searchOptC.checkMatch)
    compile1Pattern(searchOpt.checkNoMatch, searchOptC.checkNoMatch)
    for (err, filename) in walkRec(paths):
      if err != "":
        inc(gVar.errors)
        printError (err & filename)
        continue
      processFileResult(searchOptC.pattern, filename,
                        processFile(searchOptC, filename,
                                    yieldContents=optReplace in options))

# Multi-threaded version: all printing is being done in the Main thread.
# Totally nWorkers+1 additional threads are created (workers + pathProducer).
# An example of case nWorkers=2:
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
#
# The matches from each file are passed at once as FileResult type.

proc worker(initSearchOpt: SearchOpt) {.thread.} =
  searchOpt = initSearchOpt  # init thread-local var
  declareCompiledPatterns(searchOptC, SearchOptComp):
    compile1Pattern(searchOpt.pattern, searchOptC.pattern)
    compile1Pattern(searchOpt.checkMatch, searchOptC.checkMatch)
    compile1Pattern(searchOpt.checkNoMatch, searchOptC.checkNoMatch)
    while true:
      let (fileNo, filename) = searchRequestsChan.recv()
      var fileResult: FileResult
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
  resultsChan.send((true, nextFileN, "", @[]))  # pass total number of files

proc runMultiThread() =
  var
    workers = newSeq[Thread[SearchOpt]](nWorkers)
    storage = newTable[int, (string, FileResult) ]()
      # file number -> tuple[filename, fileResult - accumulated data structure]
    firstUnprocessedFile = 0  # for always processing files in the same order
  open(searchRequestsChan)
  open(resultsChan)
  for n in 0 ..< nWorkers:
    createThread(workers[n], worker, searchOpt)
  var producerThread: Thread[(seq[string], WalkOpt)]
  createThread(producerThread, pathProducer, (paths, walkOpt))
  declareCompiledPatterns(pat, SinglePattern):
    compile1Pattern(searchOpt.pattern, pat.pattern)
    template add1fileResult(fileNo: int, fname: string, fResult: FileResult) =
      storage[fileNo] = (fname, fResult)
      while storage.haskey(firstUnprocessedFile):
        let fileResult = storage[firstUnprocessedFile][1]
        let filename = storage[firstUnprocessedFile][0]
        processFileResult(pat.pattern, filename, fileResult)
        storage.del(firstUnprocessedFile)
        firstUnprocessedFile += 1
    var totalFiles = -1  # will be known when pathProducer finishes
    while totalFiles == -1 or firstUnprocessedFile < totalFiles:
      let msg = resultsChan.recv()
      if msg.finished:
        totalFiles = msg.fileNo
      else:
        add1fileResult(msg.fileNo, msg.filename, msg.fileResult)

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
    of "excludedir", "exclude-dir",   "ed": walkOpt.excludeDir.add val
    of "includedir", "include-dir",   "id": walkOpt.includeDir.add val
    of "includefile", "include-file", "if": walkOpt.includeFile.add val
    of "excludefile", "exclude-file", "ef": walkOpt.excludeFile.add val
    of "match": searchOpt.checkMatch = val
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
    of "limit", "m":
      incl(options, optLimitChars)
      if val != "":
        limitChar = parseInt(val)
    of "fit":
      incl(options, optFit)
      limitChar = terminalWidth()
    of "onlyascii", "only-ascii", "o": optOnlyAscii = true
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
checkOptions({optFit, optLimitChars}, "fit", "limit")

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
  if nWorkers == 0:
    run1Thread()
  else:
    runMultiThread()
  if gVar.errors != 0:
    printError $gVar.errors & " errors"
  printBold($gVar.matches & " matches")
  stdout.write("\n")
  if gVar.errors != 0:
    quit(1)
