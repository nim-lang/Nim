#
#
#           Nim Grep Utility
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, parseopt, pegs, re, terminal

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
  --ext:EX1|EX2|...   only search the files with the given extension(s),
                      empty one ("--ext") means files with missing extension
  --noExt:EX1|...     exclude files having given extension(s), use empty one to
                      skip files with no extension (like some binary files are)
  --includeFile:PAT   include only files whose names match the given regex PAT
  --excludeFile:PAT   skip files whose names match the given regex pattern PAT
  --excludeDir:PAT    skip directories whose names match the given regex PAT
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
  Pattern = Regex | Peg

using pattern: Pattern

var
  filenames: seq[string] = @[]
  pattern = ""
  replacement = ""
  extensions: seq[string] = @[]
  options: TOptions = {optRegex}
  skipExtensions: seq[string] = @[]
  excludeFile: seq[Regex]
  includeFile: seq[Regex]
  excludeDir: seq[Regex]
  useWriteStyled = true
  oneline = true
  linesBefore = 0
  linesAfter = 0
  linesContext = 0
  colorTheme = "simple"
  newLine = false

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

type
  SearchInfo = tuple[buf: string, filename: string]
  MatchInfo = tuple[first: int, last: int;
                    lineBeg: int, lineEnd: int, match: string]

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

proc printLinesBefore(si: SearchInfo, curMi: MatchInfo, nLines: int,
                      replMode=false) =
  # start block: print 'linesBefore' lines before current match `curMi`
  let first = beforePattern(si.buf, curMi.first-1, nLines)
  let lines = splitLines(substr(si.buf, first, curMi.first-1))
  let startLine = curMi.lineBeg - lines.len + 1
  blockHeader(si.filename, curMi.lineBeg, replMode=replMode)
  for i, l in lines:
    lineHeader(si.filename, startLine + i, isMatch = (i == lines.len - 1))
    stdout.write(l)
    if i < lines.len - 1:
      stdout.write("\n")

proc printLinesAfter(si: SearchInfo, mi: MatchInfo, nLines: int) =
  # finish block: print 'linesAfter' lines after match `mi`
  let s = si.buf
  let last = afterPattern(s, mi.last+1, nLines)
  let lines = splitLines(substr(s, mi.last+1, last))
  if lines.len == 0: # EOF
    stdout.write("\n")
  else:
    stdout.write(lines[0]) # complete the line after match itself
    stdout.write("\n")
    let skipLine =  # workaround posix line ending at the end of file
      if last == s.len-1 and s.len >= 2 and s[^1] == '\l' and s[^2] != '\c': 1
      else: 0
    for i in 1 ..< lines.len - skipLine:
      lineHeader(si.filename, mi.lineEnd + i, isMatch = false)
      stdout.write(lines[i])
      stdout.write("\n")
  if linesAfter + linesBefore >= 2 and not newLine: stdout.write("\n")

proc printBetweenMatches(si: SearchInfo, prevMi: MatchInfo, curMi: MatchInfo) =
  # continue block: print between `prevMi` and `curMi`
  let lines = si.buf.substr(prevMi.last+1, curMi.first-1).splitLines()
  stdout.write(lines[0]) # finish the line of previous Match
  if lines.len > 1:
    stdout.write("\n")
    for i in 1 ..< lines.len:
      lineHeader(si.filename, prevMi.lineEnd + i,
                 isMatch = (i == lines.len - 1))
      stdout.write(lines[i])
      if i < lines.len - 1:
        stdout.write("\n")

proc printContextBetween(si: SearchInfo, prevMi, curMi: MatchInfo) =
  # print context after previous match prevMi and before current match curMi
  let nLinesBetween = curMi.lineBeg - prevMi.lineEnd
  if nLinesBetween <= linesAfter + linesBefore + 1: # print as 1 block
    printBetweenMatches(si, prevMi, curMi)
  else: # finalize previous block and then print next block
    printLinesAfter(si, prevMi, 1+linesAfter)
    printLinesBefore(si, curMi, linesBefore+1)

proc printReplacement(si: SearchInfo, mi: MatchInfo, repl: string,
                      showRepl: bool, curPos: int,
                      newBuf: string, curLine: int) =
  printLinesBefore(si, mi, linesBefore+1)
  printMatch(si.fileName, mi)
  printLinesAfter(si, mi, 1+linesAfter)
  stdout.flushFile()
  if showRepl:
    let newSi: SearchInfo = (buf: newBuf, filename: si.filename)
    let miForNewBuf: MatchInfo =
      (first: newBuf.len, last: newBuf.len,
       lineBeg: curLine, lineEnd: curLine, match: "")
    printLinesBefore(newSi, miForNewBuf, linesBefore+1, replMode=true)

    let replLines = countLineBreaks(repl, 0, repl.len-1)
    let miFixLines: MatchInfo =
      (first: mi.first, last: mi.last,
       lineBeg: curLine, lineEnd: curLine + replLines, match: repl)
    printMatch(si.fileName, miFixLines)
    printLinesAfter(si, miFixLines, 1+linesAfter)
    stdout.flushFile()

proc doReplace(si: SearchInfo, mi: MatchInfo, i: int, r: string;
               newBuf: var string, curLine: var int, reallyReplace: var bool) =
  newBuf.add(si.buf.substr(i, mi.first-1))
  inc(curLine, countLineBreaks(si.buf, i, mi.first-1))
  if optConfirm in options:
    printReplacement(si, mi, r, showRepl=true, i, newBuf, curLine)
    case confirm()
    of ceAbort: quit(0)
    of ceYes: reallyReplace = true
    of ceAll:
      reallyReplace = true
      options.excl(optConfirm)
    of ceNo:
      reallyReplace = false
    of ceNone:
      reallyReplace = false
      options.excl(optConfirm)
  else:
    printReplacement(si, mi, r, showRepl=reallyReplace, i, newBuf, curLine)
  if reallyReplace:
    newBuf.add(r)
    inc(curLine, countLineBreaks(r, 0, r.len-1))
  else:
    newBuf.add(mi.match)
    inc(curLine, countLineBreaks(mi.match, 0, mi.match.len-1))

proc processFile(pattern; filename: string; counter: var int, errors: var int) =
  var filenameShown = false
  template beforeHighlight =
    if not filenameShown and optVerbose notin options and not oneline:
      printBlockFile(filename)
      stdout.write("\n")
      stdout.flushFile()
      filenameShown = true

  var buffer: string
  if optFilenames in options:
    buffer = filename
  else:
    try:
      buffer = system.readFile(filename)
    except IOError:
      printError "Error: cannot open file: " & filename
      inc(errors)
      return
  if optVerbose in options:
    printFile(filename)
    stdout.write("\n")
    stdout.flushFile()
  var result: string

  if optReplace in options:
    result = newStringOfCap(buffer.len)

  var lineRepl = 1
  let si: SearchInfo = (buf: buffer, filename: filename)
  var prevMi, curMi: MatchInfo
  curMi.lineEnd = 1
  var i = 0
  var matches: array[0..re.MaxSubpatterns-1, string]
  for j in 0..high(matches): matches[j] = ""
  var reallyReplace = true
  while i < buffer.len:
    let t = findBounds(buffer, pattern, matches, i)
    if t.first < 0 or t.last < t.first:
      if optReplace notin options and prevMi.lineBeg != 0: # finalize last match
        printLinesAfter(si, prevMi, 1+linesAfter)
        stdout.flushFile()
      break

    let lineBeg = curMi.lineEnd + countLineBreaks(buffer, i, t.first-1)
    curMi = (first: t.first,
             last: t.last,
             lineBeg: lineBeg,
             lineEnd: lineBeg + countLineBreaks(buffer, t.first, t.last),
             match: buffer.substr(t.first, t.last))
    beforeHighlight()
    inc counter
    if optReplace notin options:
      if prevMi.lineBeg == 0: # no previous match, so no previous block to finalize
        printLinesBefore(si, curMi, linesBefore+1)
      else:
        printContextBetween(si, prevMi, curMi)
      printMatch(si.fileName, curMi)
      if t.last == buffer.len - 1:
        stdout.write("\n")
      stdout.flushFile()
    else:
      let r = replace(curMi.match, pattern, replacement % matches)
      doReplace(si, curMi, i, r, result, lineRepl, reallyReplace)

    i = t.last+1
    prevMi = curMi

  if optReplace in options:
    result.add(substr(buffer, i))  # finalize new buffer after last match
    var f: File
    if open(f, filename, fmWrite):
      f.write(result)
      f.close()
    else:
      quit "cannot open file for overwriting: " & filename

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

proc walker(pattern; dir: string; counter: var int, errors: var int) =
  if dirExists(dir):
    for kind, path in walkDir(dir):
      case kind
      of pcFile:
        if path.hasRightFileName:
          processFile(pattern, path, counter, errors)
      of pcLinkToFile:
        if optFollow in options and path.hasRightFileName:
          processFile(pattern, path, counter, errors)
      of pcDir:
        if optRecursive in options and path.hasRightDirectory:
          walker(pattern, path, counter, errors)
      of pcLinkToDir:
        if optFollow in options and optRecursive in options and
           path.hasRightDirectory:
          walker(pattern, path, counter, errors)
  elif fileExists(dir):
    processFile(pattern, dir, counter, errors)
  else:
    printError "Error: no such file or directory: " & dir
    inc(errors)

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
      filenames.add(key)
    elif pattern.len == 0:
      pattern = key
    elif options.contains(optReplace) and replacement.len == 0:
      replacement = key
    else:
      filenames.add(key)
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
    of "ext": extensions.add val.split('|')
    of "noext": skipExtensions.add val.split('|')
    of "excludedir", "exclude-dir": excludeDir.add rex(val)
    of "includefile", "include-file": includeFile.add rex(val)
    of "excludefile", "exclude-file": excludeFile.add rex(val)
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
  var counter = 0
  var errors = 0
  if filenames.len == 0:
    filenames.add(os.getCurrentDir())
  if optRegex notin options:
    if optWord in options:
      pattern = r"(^ / !\letter)(" & pattern & r") !\letter"
    if optIgnoreStyle in options:
      pattern = "\\y " & pattern
    elif optIgnoreCase in options:
      pattern = "\\i " & pattern
    let pegp = peg(pattern)
    for f in items(filenames):
      walker(pegp, f, counter, errors)
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
    for f in items(filenames):
      walker(rep, f, counter, errors)
  if errors != 0:
    printError $errors & " errors"
  stdout.write($counter & " matches\n")
  if errors != 0:
    quit(1)
