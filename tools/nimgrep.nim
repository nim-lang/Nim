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
  Version = "1.6.0"
  Usage = "nimgrep - Nim Grep Searching and Replacement Utility Version " &
  Version & """

  (c) 2012-2020 Andreas Rumpf
""" & slurp "../doc/nimgrep_cmdline.txt"

# Limitations / ideas / TODO:
# * No unicode support with --cols
# * Consider making --onlyAscii default, since dumping binary data has
#   stability and security repercussions
# * Mode - reads entire buffer by whole from stdin, which is bad for streaming.
#   To implement line-by-line reading after adding option to turn off
#   multiline matches
# * Add some form of file pre-processing, e.g. feed binary files to utility
#   `strings` and then do the search inside these strings
# * Add --showCol option to also show column (of match), not just line; it
#   makes it easier when jump to line+col in an editor or on terminal


# Search results for a file are modelled by these levels:
# FileResult -> Block -> Output/Chunk -> SubLine
#
# 1. SubLine is an entire line or its part.
#
# 2. Chunk, which is a sequence of SubLine, represents a match and its
#    surrounding context.
#    Output is a Chunk or one of auxiliary results like an openError.
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
    optRex, optFollow, optCount, optLimitChars, optPipe
  TOptions = set[TOption]
  TConfirmEnum = enum
    ceAbort, ceYes, ceAll, ceNo, ceNone
  Bin = enum
    biOn, biOnly, biOff
  Pattern = Regex | Peg
  MatchInfo = tuple[first: int, last: int;
                    lineBeg: int, lineEnd: int, match: string]
  outputKind = enum
    openError, rejected, justCount,
    blockFirstMatch, blockNextMatch, blockEnd, fileContents, outputFileName
  Output = object
    case kind: outputKind
    of openError: msg: string           # file/directory not found
    of rejected: reason: string         # when the file contents do not pass
    of justCount: matches: int          # the only output for option --count
    of blockFirstMatch, blockNextMatch: # the normal case: match itself
      pre: string
      match: MatchInfo
    of blockEnd:                        # block ending right after prev. match
      blockEnding: string
      firstLine: int
        # == last lineN of last match
    of fileContents:                    # yielded for --replace only
      buffer: string
    of outputFileName:                  # yielded for --filenames when no
      name: string                      #   PATTERN was provided
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
    patternSet: bool     # to distinguish uninitialized 'pattern' and empty one
    pattern: string      # main PATTERN
    checkMatch: string   # --match
    checkNoMatch: string # --nomatch
    checkBin: Bin        # --bin
  SearchOptComp[Pat] = tuple  # a compiled version of the previous
    pattern: Pat
    checkMatch: Pat
    checkNoMatch: Pat
  SinglePattern[PAT] = tuple  # compile single pattern for replacef
    pattern: PAT
  Column = tuple  # current column info for the cropping (--limit) feature
    terminal: int  # column in terminal emulator
    file: int      # column in file (for correct Tab processing)
    overflowMatches: int

var
  paths: seq[string] = @[]
  replacement = ""
  replacementSet = false
    # to distinguish between uninitialized 'replacement' and empty one
  options: TOptions = {optRegex}
  walkOpt {.threadvar.}: WalkOpt
  searchOpt {.threadvar.}: SearchOpt
  sortTime = false
  sortTimeOrder = SortOrder.Ascending
  useWriteStyled = true
  oneline = true  # turned off by --group
  expandTabs = true  # Tabs are expanded in oneline mode
  linesBefore = 0
  linesAfter = 0
  linesContext = 0
  newLine = false
  gVar = (matches: 0, errors: 0, reallyReplace: true)
    # gVar - variables that can change during search/replace
  nWorkers = 0  # run in single thread by default
  searchRequestsChan: Channel[Trequest]
  resultsChan: Channel[Tresult]
  colorTheme: string = "simple"
  limitCharUsr = high(int)  # don't limit line width by default
  termWidth = 80
  optOnlyAscii = false

searchOpt.checkBin = biOn

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
    of "simple", "bnw":
      stdout.styledWrite(if s == " ": styleReverse else: styleBright, s)
    of "ack", "gnu": stdout.styledWrite(styleReverse, fgBlue, bgDefault, s)

proc printError(s: string) =
  whenColors:
    case colorTheme
    of "simple", "bnw": stdout.styledWriteLine(styleBright, s)
    of "ack", "gnu": stdout.styledWriteLine(styleReverse, fgRed, bgDefault, s)
  stdout.flushFile()

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

proc printContents(s: string, isMatch: bool) =
  if isMatch:
    writeColored(s)
  else:
    stdout.write(s)

proc writeArrow(s: string) =
  whenColors:
    stdout.styledWrite(styleReverse, s)

const alignment = 6  # selected so that file contents start at 8, i.e.
                     # Tabs expand correctly without additional care

proc blockHeader(filename: string, line: int|string, replMode=false) =
  if replMode:
    writeArrow("     ->\n")
  elif newLine and optFilenames notin options and optPipe notin options:
    if oneline:
      printBlockFile(filename)
      printBlockLineN(":" & $line & ":")
    else:
      printBlockLineN($line.`$`.align(alignment) & ":")
    stdout.write("\n")

proc newLn(curCol: var Column) =
  stdout.write("\n")
  curCol.file = 0
  curCol.terminal = 0

# We reserve 10+3 chars on the right in --cols mode (optLimitChars).
# If the current match touches this right margin, subLine before it will
# be cropped (even if space is enough for subLine after the match — we
# currently don't have a way to know it since we get it afterwards).
const matchPaddingFromRight = 10
const ellipsis = "..."

proc lineHeader(filename: string, line: int|string, isMatch: bool,
                curCol: var Column) =
  let lineSym =
    if isMatch: $line & ":"
    else: $line & " "
  if not newLine and optFilenames notin options and optPipe notin options:
    if oneline:
      printFile(filename)
      printLineN(":" & lineSym, isMatch)
      curcol.terminal += filename.len + 1 + lineSym.len
    else:
      printLineN(lineSym.align(alignment+1), isMatch)
      curcol.terminal += lineSym.align(alignment+1).len
    stdout.write(" "); curCol.terminal += 1
    curCol.terminal = curCol.terminal mod termWidth
    if optLimitChars in options and
        curCol.terminal > limitCharUsr - matchPaddingFromRight - ellipsis.len:
      newLn(curCol)

proc reserveChars(mi: MatchInfo): int =
  if optLimitChars in options:
    let patternChars = afterPattern(mi.match, 0) + 1
    result = patternChars + ellipsis.len + matchPaddingFromRight
  else:
    result = 0

# Our substitutions of non-printable symbol to ASCII character are similar to
# those of programm 'less'.
const lowestAscii  = 0x20  # lowest ASCII Latin printable symbol (@)
const largestAscii = 0x7e
const by2ascii = 2  # number of ASCII chars to represent chars < lowestAscii
const by3ascii = 3  # number of ASCII chars to represent chars > largestAscii

proc printExpanded(s: string, curCol: var Column, isMatch: bool,
                   limitChar: int) =
  # Print taking into account tabs and optOnlyAscii (and also optLimitChar:
  # the proc called from printCropped but we need to check column < limitChar
  # also here, since exact cut points are known only after tab expansion).
  # With optOnlyAscii non-ascii chars are highlighted even in matches.
  #
  # use buffer because:
  # 1) we need to print non-ascii character inside matches while keeping the
  #    amount of color escape sequences minimal.
  # 2) there is a report that fwrite buffering is slow on MacOS
  #    https://github.com/nim-lang/Nim/pull/15612#discussion_r510538326
  const bufSize = 8192  # typical for fwrite too
  var buffer: string
  const normal = 0
  const special = 1
  var lastAdded = normal
  template dumpBuf() =
    if lastAdded == normal:
      printContents(buffer, isMatch)
    else:
      printSpecial(buffer)
  template addBuf(i: int, s: char|string, size: int) =
    if lastAdded != i or buffer.len + size > bufSize:
      dumpBuf()
      buffer.setlen(0)
    buffer.add s
    lastAdded = i
  for c in s:
    let charsAllowed = limitChar - curCol.terminal
    if charsAllowed <= 0:
      break
    if lowestAscii <= int(c) and int(c) <= largestAscii:  # ASCII latin
      addBuf(normal, c, 1)
      curCol.file += 1; curCol.terminal += 1
    elif (not optOnlyAscii) and c != '\t':  # the same, print raw
      addBuf(normal, c, 1)
      curCol.file += 1; curCol.terminal += 1
    elif c == '\t':
      let spaces = 8 - (curCol.file mod 8)
      let spacesAllowed = min(spaces, charsAllowed)
      curCol.file += spaces
      curCol.terminal += spacesAllowed
      if expandTabs:
        if optOnlyAscii:  # print a nice box for tab
          addBuf(special, " ", 1)
          addBuf(normal, " ".repeat(spacesAllowed-1), spacesAllowed-1)
        else:
          addBuf(normal, " ".repeat(spacesAllowed), spacesAllowed)
      else:
        addBuf(normal, '\t', 1)
    else:  # substitute characters that are not ACSII Latin
      if int(c) < lowestAscii:
        let substitute = char(int(c) + 0x40)  # use common "control codes"
        addBuf(special, "^" & substitute, by2ascii)
        curCol.terminal += by2ascii
      else:  # int(c) > largestAscii
        curCol.terminal += by3ascii
        let substitute = '\'' & c.BiggestUInt.toHex(2)
        addBuf(special, substitute, by3ascii)
      curCol.file += 1
  if buffer.len > 0:
    dumpBuf()

template nextCharacter(c: char, file: var int, term: var int) =
  if lowestAscii <= int(c) and int(c) <= largestAscii:  # ASCII latin
    file += 1
    term += 1
  elif (not optOnlyAscii) and c != '\t':  # the same, print raw
    file += 1
    term += 1
  elif c == '\t':
    term += 8 - (file mod 8)
    file += 8 - (file mod 8)
  elif int(c) < lowestAscii:
    file += 1
    term += by2ascii
  else:  # int(c) > largestAscii:
    file += 1
    term += by3ascii

proc calcTermLen(s: string, firstCol: int, chars: int, fromLeft: bool): int =
  # calculate additional length added by Tabs expansion and substitutions
  var col = firstCol
  var first, last: int
  if fromLeft:
    first = max(0, s.len - chars)
    last = s.len - 1
  else:
    first = 0
    last = min(s.len - 1, chars - 1)
  for c in s[first .. last]:
    nextCharacter(c, col, result)

proc printCropped(s: string, curCol: var Column, fromLeft: bool,
                  limitChar: int, isMatch = false) =
  # print line `s`, may be cropped if option --cols was set
  const eL = ellipsis.len
  if optLimitChars notin options:
    if not expandTabs and not optOnlyAscii:  # for speed mostly
      printContents(s, isMatch)
    else:
      printExpanded(s, curCol, isMatch, limitChar)
  else:  # limit columns, expand Tabs is also forced
    var charsAllowed = limitChar - curCol.terminal
    if fromLeft and charsAllowed < eL:
      charsAllowed = eL
    if (not fromLeft) and charsAllowed <= 0:
      # already overflown and ellipsis shold be in place
      return
    let fullLenWithin = calcTermLen(s, curCol.file, charsAllowed, fromLeft)
    # additional length from Tabs and special symbols
    let addLen = fullLenWithin - min(s.len, charsAllowed)
    # determine that the string is guaranteed to fit within `charsAllowed`
    let fits =
      if s.len > charsAllowed:
        false
      else:
        if isMatch: fullLenWithin <= charsAllowed - eL
        else: fullLenWithin <= charsAllowed
    if fits:
      printExpanded(s, curCol, isMatch, limitChar = high(int))
    else:
      if fromLeft:
        printBold ellipsis
        curCol.terminal += eL
        # find position `pos` where the right side of line will fit charsAllowed
        var col = 0
        var term = 0
        var pos = min(s.len, max(0, s.len - (charsAllowed - eL)))
        while pos <= s.len - 1:
          let c = s[pos]
          nextCharacter(c, col, term)
          if term >= addLen:
            break
          inc pos
        curCol.file = pos
        # TODO don't expand tabs when cropped from the left - difficult, meaningless
        printExpanded(s[pos .. s.len - 1], curCol, isMatch,
                      limitChar = high(int))
      else:
        let last = max(-1, min(s.len - 1, charsAllowed - eL - 1))
        printExpanded(s[0 .. last], curCol, isMatch, limitChar-eL)
        let numDots = limitChar - curCol.terminal
        printBold ".".repeat(numDots)
        curCol.terminal = limitChar

proc printMatch(fileName: string, mi: MatchInfo, curCol: var Column) =
  let sLines = mi.match.splitLines()
  for i, l in sLines:
    if i > 0:
      lineHeader(filename, mi.lineBeg + i, isMatch = true, curCol)
    let charsAllowed = limitCharUsr - curCol.terminal
    if charsAllowed > 0:
      printCropped(l, curCol, fromLeft = false, limitCharUsr, isMatch = true)
    else:
      curCol.overflowMatches += 1
    if i < sLines.len - 1:
      newLn(curCol)

proc getSubLinesBefore(buf: string, curMi: MatchInfo): string =
  let first = beforePattern(buf, curMi.first-1, linesBefore+1)
  result = substr(buf, first, curMi.first-1)

proc printSubLinesBefore(filename: string, beforeMatch: string, lineBeg: int,
                         curCol: var Column, reserveChars: int,
                         replMode=false) =
  # start block: print 'linesBefore' lines before current match `curMi`
  let sLines = splitLines(beforeMatch)
  let startLine = lineBeg - sLines.len + 1
  blockHeader(filename, lineBeg, replMode=replMode)
  for i, l in sLines:
    let isLastLine = i == sLines.len - 1
    lineHeader(filename, startLine + i, isMatch = isLastLine, curCol)
    let limit = if isLastLine: limitCharUsr - reserveChars else: limitCharUsr
    l.printCropped(curCol, fromLeft = isLastLine, limitChar = limit)
    if not isLastLine:
      newLn(curCol)

proc getSubLinesAfter(buf: string, mi: MatchInfo): string =
  let last = afterPattern(buf, mi.last+1, 1+linesAfter)
  let skipByte =  # workaround posix: suppress extra line at the end of file
    if (last == buf.len-1 and buf.len >= 2 and
        buf[^1] == '\l' and buf[^2] != '\c'): 1
    else: 0
  result = substr(buf, mi.last+1, last - skipByte)

proc printOverflow(filename: string, line: int, curCol: var Column) =
  if curCol.overflowMatches > 0:
    lineHeader(filename, line, isMatch = true, curCol)
    printBold("(" & $curCol.overflowMatches & " matches skipped)")
    newLn(curCol)
    curCol.overflowMatches = 0

proc printSubLinesAfter(filename: string, afterMatch: string, matchLineEnd: int,
                        curCol: var Column) =
  # finish block: print 'linesAfter' lines after match `mi`
  let sLines = splitLines(afterMatch)
  if sLines.len == 0: # EOF
    newLn(curCol)
  else:
    sLines[0].printCropped(curCol, fromLeft = false, limitCharUsr)
      # complete the line after the match itself
    newLn(curCol)
    printOverflow(filename, matchLineEnd, curCol)
    for i in 1 ..< sLines.len:
      lineHeader(filename, matchLineEnd + i, isMatch = false, curCol)
      sLines[i].printCropped(curCol, fromLeft = false, limitCharUsr)
      newLn(curCol)

proc getSubLinesBetween(buf: string, prevMi: MatchInfo,
                        curMi: MatchInfo): string =
  buf.substr(prevMi.last+1, curMi.first-1)

proc printBetweenMatches(filename: string, betweenMatches: string,
                         lastLineBeg: int,
                         curCol: var Column, reserveChars: int) =
  # continue block: print between `prevMi` and `curMi`
  let sLines = betweenMatches.splitLines()
  sLines[0].printCropped(curCol, fromLeft = false, limitCharUsr)
    # finish the line of previous Match
  if sLines.len > 1:
    newLn(curCol)
    printOverflow(filename, lastLineBeg - sLines.len + 1, curCol)
    for i in 1 ..< sLines.len:
      let isLastLine = i == sLines.len - 1
      lineHeader(filename, lastLineBeg - sLines.len + i + 1,
                 isMatch = isLastLine, curCol)
      let limit = if isLastLine: limitCharUsr - reserveChars else: limitCharUsr
      sLines[i].printCropped(curCol, fromLeft = isLastLine, limitChar = limit)
      if not isLastLine:
        newLn(curCol)

proc printReplacement(fileName: string, buf: string, mi: MatchInfo,
                      repl: string, showRepl: bool, curPos: int,
                      newBuf: string, curLine: int) =
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
    if linesAfter + linesBefore >= 2 and not newLine: stdout.write("\n")
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
  elif optPipe notin options:
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
  of blockFirstMatch, blockNextMatch: inc(gVar.matches)
  of justCount: inc(gVar.matches, output.matches)
  of openError: inc(gVar.errors)
  of rejected, blockEnd, fileContents, outputFileName: discard

proc printInfo(filename:string, output: Output) =
  case output.kind
  of openError:
    printError("cannot open path '" & filename & "': " & output.msg)
  of rejected:
    if optVerbose in options:
      echo "(rejected: ", output.reason, ")"
  of justCount:
    echo " (" & $output.matches & " matches)"
  of blockFirstMatch, blockNextMatch, blockEnd, fileContents, outputFileName:
    discard

proc printOutput(filename: string, output: Output, curCol: var Column) =
  case output.kind
  of openError, rejected, justCount: printInfo(filename, output)
  of fileContents: discard # impossible
  of outputFileName:
    printCropped(output.name, curCol, fromLeft=false, limitCharUsr)
    newLn(curCol)
  of blockFirstMatch:
    printSubLinesBefore(filename, output.pre, output.match.lineBeg,
                        curCol, reserveChars(output.match))
    printMatch(filename, output.match, curCol)
  of blockNextMatch:
    printBetweenMatches(filename, output.pre, output.match.lineBeg,
                        curCol, reserveChars(output.match))
    printMatch(filename, output.match, curCol)
  of blockEnd:
    printSubLinesAfter(filename, output.blockEnding, output.firstLine, curCol)
    if linesAfter + linesBefore >= 2 and not newLine and
       optFilenames notin options: stdout.write("\n")

iterator searchFile(pattern: Pattern; buffer: string): Output =
  var prevMi, curMi: MatchInfo
  prevMi.lineEnd = 1
  var i = 0
  var matches: array[0..re.MaxSubpatterns-1, string]
  for j in 0..high(matches): matches[j] = ""
  while true:
    let t = findBounds(buffer, pattern, matches, i)
    if t.first < 0 or t.last < t.first:
      if prevMi.lineBeg != 0: # finalize last match
        yield Output(kind: blockEnd,
                     blockEnding: getSubLinesAfter(buffer, prevMi),
                     firstLine: prevMi.lineEnd)
      break

    let lineBeg = prevMi.lineEnd + countLineBreaks(buffer, i, t.first-1)
    curMi = (first: t.first,
             last: t.last,
             lineBeg: lineBeg,
             lineEnd: lineBeg + countLineBreaks(buffer, t.first, t.last),
             match: buffer.substr(t.first, t.last))
    if prevMi.lineBeg == 0: # no prev. match, so no prev. block to finalize
      let pre = getSubLinesBefore(buffer, curMi)
      prevMi = curMi
      yield Output(kind: blockFirstMatch, pre: pre, match: move(curMi))
    else:
      let nLinesBetween = curMi.lineBeg - prevMi.lineEnd
      if nLinesBetween <= linesAfter + linesBefore + 1: # print as 1 block
        let pre =  getSubLinesBetween(buffer, prevMi, curMi)
        prevMi = curMi
        yield Output(kind: blockNextMatch, pre: pre, match: move(curMi))
      else: # finalize previous block and then print next block
        let after = getSubLinesAfter(buffer, prevMi)
        yield Output(kind: blockEnd, blockEnding: after,
                     firstLine: prevMi.lineEnd)
        let pre = getSubLinesBefore(buffer, curMi)
        prevMi = curMi
        yield Output(kind: blockFirstMatch,
                     pre: pre,
                     match: move(curMi))
    i = t.last+1
  when typeof(pattern) is Regex:
    if buffer.len > MaxReBufSize:
      yield Output(kind: openError, msg: "PCRE size limit is " & $MaxReBufSize)

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

  var error = false
  if optFilenames in options:
    buffer = filename
  elif optPipe in options:
    buffer = stdin.readAll()
  else:
    try:
      buffer = system.readFile(filename)
    except IOError as e:
      yield Output(kind: openError, msg: "readFile failed")
      error = true

  if not error:
    var reject = false
    var reason: string
    if searchOpt.checkBin in {biOff, biOnly}:
      let isBin = detectBin(buffer)
      if isBin and searchOpt.checkBin == biOff:
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
      yield Output(kind: rejected, reason: move(reason))
    elif optFilenames in options and searchOpt.pattern == "":
      yield Output(kind: outputFileName, name: move(buffer))
    else:
      var found = false
      var cnt = 0
      for output in searchFile(searchOptC.pattern, buffer):
        found = true
        if optCount notin options:
          yield output
        else:
          if output.kind in {blockFirstMatch, blockNextMatch}:
            inc(cnt)
      if optCount in options and cnt > 0:
        yield Output(kind: justCount, matches: cnt)
      if yieldContents and found and optCount notin options:
        yield Output(kind: fileContents, buffer: move(buffer))


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
      if filename.contains(pat):
        matched = true
        break
    if not matched: return false
  for pat in walkOptC.excludeFile:
    if filename.contains(pat): return false
  let dirname = path.parentDir
  if walkOptC.includeDir.len != 0:
    var matched = false
    for pat in walkOptC.includeDir:
      if dirname.contains(pat):
        matched = true
        break
    if not matched: return false
  result = true

proc hasRightDirectory(path: string, walkOptC: WalkOptComp[Pattern]): bool =
  let dirname = path.lastPathPart
  for pat in walkOptC.excludeDir:
    if dirname.contains(pat): return false
  result = true

iterator walkDirBasic(dir: string, walkOptC: WalkOptComp[Pattern]): string
         {.closure.} =
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

iterator walkRec(paths: seq[string]): tuple[error: string, filename: string]
         {.closure.} =
  declareCompiledPatterns(walkOptC, WalkOptComp):
    walkOptC.excludeFile.add walkOpt.excludeFile.compileArray()
    walkOptC.includeFile.add walkOpt.includeFile.compileArray()
    walkOptC.includeDir.add  walkOpt.includeDir.compileArray()
    walkOptC.excludeDir.add  walkOpt.excludeDir.compileArray()
    for path in paths:
      if dirExists(path):
        for p in walkDirBasic(path, walkOptC):
          yield ("", p)
      else:
        yield (
          if fileExists(path): ("", path)
          else: ("Error: no such file or directory: ", path))

proc replaceMatches(pattern: Pattern; filename: string, buffer: string,
                    fileResult: FileResult) =
  var newBuf = newStringOfCap(buffer.len)

  var changed = false
  var lineRepl = 1
  var i = 0
  for output in fileResult:
    if output.kind in {blockFirstMatch, blockNextMatch}:
      let curMi = output.match
      let r = replacef(curMi.match, pattern, replacement)
      if replace1match(filename, buffer, curMi, i, r, newBuf, lineRepl):
        changed = true
      i = curMi.last + 1
  if changed and optPipe notin options:
    newBuf.add(substr(buffer, i))  # finalize new buffer after last match
    var f: File
    if open(f, filename, fmWrite):
      f.write(newBuf)
      f.close()
    else:
      printError "cannot open file for overwriting: " & filename
      inc(gVar.errors)
  elif optPipe in options:  # always print new buffer to stdout in pipe mode
    newBuf.add(substr(buffer, i))  # finalize new buffer after last match
    stdout.write(newBuf)

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
    var toFlush: bool
    for output in fileResult:
      updateCounters(output)
      toFlush = true
      if output.kind notin {rejected, openError, justCount} and not oneline:
        showFilename
      if output.kind == justCount and oneline:
        printFile(filename & ":")
      printOutput(filename, output, curCol)
      if nWorkers == 0 and output.kind in {blockFirstMatch, blockNextMatch}:
        stdout.flushFile()  # flush immediately in single thread mode
    if toFlush: stdout.flushFile()
  else:
    var buffer = ""
    var matches: FileResult
    for output in fileResult:
      updateCounters(output)
      case output.kind
      of rejected, openError, justCount, outputFileName:
        printInfo(filename, output)
      of blockFirstMatch, blockNextMatch, blockEnd:
        matches.add(output)
      of fileContents: buffer = output.buffer
    if matches.len > 0:
      replaceMatches(pattern, filename, buffer, matches)

proc run1Thread() =
  declareCompiledPatterns(searchOptC, SearchOptComp):
    compile1Pattern(searchOpt.pattern, searchOptC.pattern)
    compile1Pattern(searchOpt.checkMatch, searchOptC.checkMatch)
    compile1Pattern(searchOpt.checkNoMatch, searchOptC.checkNoMatch)
    if optPipe in options:
      processFileResult(searchOptC.pattern, "-",
                        processFile(searchOptC, "-",
                                    yieldContents=optReplace in options))
    for entry in walkRec(paths):
      if entry.error != "":
        inc(gVar.errors)
        printError (entry.error & entry.filename)
        continue
      processFileResult(searchOptC.pattern, entry.filename,
                        processFile(searchOptC, entry.filename,
                                    yieldContents=optReplace in options))

# Multi-threaded version: all printing is being done in the Main thread.
# Totally nWorkers+1 additional threads are created (workers + pathProducer).
# An example of case nWorkers=2:
#
#  ------------------  initial paths   -------------------
#  |  Main thread   |----------------->|  pathProducer   |
#  ------------------                  -------------------
#             ^                          |        | 
# resultsChan |       walking errors,    |        | searchRequestsChan
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
  for entry in walkRec(paths):
    if entry.error == "":
      searchRequestsChan.send((nextFileN, entry.filename))
    else:
      resultsChan.send((false, nextFileN, entry.filename,
                        @[Output(kind: openError, msg: entry.error)]))
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

proc parseNonNegative(str: string, key: string): int =
  try:
    result = parseInt(str)
  except ValueError:
    reportError("Option " & key & " requires an integer but '" &
                str & "' was given")
  if result < 0:
    reportError("A positive integer is expected for option " & key)

when defined(posix):
  useWriteStyled = terminal.isatty(stdout)
  # that should be before option processing to allow override of useWriteStyled

for kind, key, val in getopt():
  case kind
  of cmdArgument:
    if options.contains(optStdin):
      paths.add(key)
    elif not searchOpt.patternSet:
      searchOpt.pattern = key
      searchOpt.patternSet = true
    elif options.contains(optReplace) and not replacementSet:
      replacement = key
      replacementSet = true
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
    of "threads", "j":
      if val == "":
        nWorkers = countProcessors()
      else:
        nWorkers = parseNonNegative(val, key)
    of "ext": walkOpt.extensions.add val.split('|')
    of "noext", "no-ext": walkOpt.skipExtensions.add val.split('|')
    of "excludedir", "exclude-dir",   "ed": walkOpt.excludeDir.add val
    of "includedir", "include-dir",   "id": walkOpt.includeDir.add val
    of "includefile", "include-file", "if": walkOpt.includeFile.add val
    of "excludefile", "exclude-file", "ef": walkOpt.excludeFile.add val
    of "match": searchOpt.checkMatch = val
    of "nomatch":
      searchOpt.checkNoMatch = val
    of "bin":
      case val
      of "on": searchOpt.checkBin = biOn
      of "off": searchOpt.checkBin = biOff
      of "only": searchOpt.checkBin = biOnly
      else: reportError("unknown value for --bin")
    of "text", "t": searchOpt.checkBin = biOff
    of "count": incl(options, optCount)
    of "sorttime", "sort-time", "s":
      case normalize(val)
      of "off": sortTime = false
      of "", "on", "asc", "ascending":
        sortTime = true
        sortTimeOrder = SortOrder.Ascending
      of "desc", "descending":
        sortTime = true
        sortTimeOrder = SortOrder.Descending
      else: reportError("invalid value '" & val & "' for --sortTime")
    of "nocolor", "no-color": useWriteStyled = false
    of "color":
      case val
      of "auto": discard
      of "off", "never", "false": useWriteStyled = false
      of "", "on", "always", "true": useWriteStyled = true
      else: reportError("invalid value '" & val & "' for --color")
    of "colortheme", "color-theme":
      colortheme = normalize(val)
      if colortheme notin ["simple", "bnw", "ack", "gnu"]:
        reportError("unknown colortheme '" & val & "'")
    of "beforecontext", "before-context", "b":
      linesBefore = parseNonNegative(val, key)
    of "aftercontext", "after-context", "a":
      linesAfter = parseNonNegative(val, key)
    of "context", "c":
      linesContext = parseNonNegative(val, key)
    of "newline", "l":
      newLine = true
      # Tabs are aligned automatically for --group, --newLine, --filenames
      expandTabs = false
    of "group", "g":
      oneline = false
      expandTabs = false
    of "cols", "%":
      incl(options, optLimitChars)
      termWidth = terminalWidth()
      if val == "auto" or key == "%":
        limitCharUsr = termWidth
        when defined(windows):  # Windows cmd & powershell add an empty line
          limitCharUsr -= 1     # when printing '\n' right after the last column
      elif val == "":
        limitCharUsr = 80
      else:
        limitCharUsr = parseNonNegative(val, key)
    of "onlyascii", "only-ascii", "@":
      if val == "" or val == "on" or key == "@":
        optOnlyAscii = true
      elif val == "off":
        optOnlyAscii = false
      else:
        printError("unknown value for --onlyAscii option")
    of "verbose": incl(options, optVerbose)
    of "filenames":
      incl(options, optFilenames)
      expandTabs = false
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
    of "": incl(options, optPipe)
    else: reportError("unrecognized option '" & key & "'")
  of cmdEnd: assert(false) # cannot happen

checkOptions({optFind, optReplace}, "find", "replace")
checkOptions({optCount, optReplace}, "count", "replace")
checkOptions({optPeg, optRegex}, "peg", "re")
checkOptions({optIgnoreCase, optIgnoreStyle}, "ignore_case", "ignore_style")
checkOptions({optFilenames, optReplace}, "filenames", "replace")
checkOptions({optPipe, optStdin}, "-", "stdin")
checkOptions({optPipe, optFilenames}, "-", "filenames")
checkOptions({optPipe, optConfirm}, "-", "confirm")
checkOptions({optPipe, optRecursive}, "-", "recursive")

linesBefore = max(linesBefore, linesContext)
linesAfter  = max(linesAfter,  linesContext)

if optPipe in options and paths.len != 0:
  reportError("both - and paths are specified")

if optStdin in options:
  searchOpt.pattern = ask("pattern [ENTER to exit]: ")
  if searchOpt.pattern.len == 0: quit(0)
  if optReplace in options:
    replacement = ask("replacement [supports $1, $# notations]: ")

if optReplace in options and not replacementSet:
  reportError("provide REPLACEMENT as second argument (use \"\" for empty one)")
if optReplace in options and paths.len == 0 and optPipe notin options:
  reportError("provide paths for replacement explicitly (use . for current directory)")

if searchOpt.pattern == "" and optFilenames notin options:
  reportError("empty pattern was given")
else:
  if paths.len == 0 and optPipe notin options:
    paths.add(".")
  if optPipe in options or nWorkers == 0:
    run1Thread()
  else:
    runMultiThread()
  if gVar.errors != 0:
    printError $gVar.errors & " errors"
  if searchOpt.pattern != "":
    # PATTERN allowed to be empty if --filenames is given
    printBold($gVar.matches & " matches")
    stdout.write("\n")
  if gVar.errors != 0:
    quit(1)
