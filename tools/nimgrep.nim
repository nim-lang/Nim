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
  Version = "0.9"
  Usage = "nimgrep - Nim Grep Utility Version " & Version & """

  (c) 2012 Andreas Rumpf
Usage:
  nimgrep [options] [pattern] [replacement] (file/directory)*
Options:
  --find, -f          find the pattern (default)
  --replace, -r       replace the pattern
  --peg               pattern is a peg
  --re                pattern is a regular expression (default); extended 
                      syntax for the regular expression is always turned on
  --recursive         process directories recursively
  --confirm           confirm each occurrence/replacement; there is a chance 
                      to abort any time without touching the file
  --stdin             read pattern from stdin (to avoid the shell's confusing
                      quoting rules)
  --word, -w          the match should have word boundaries (buggy for pegs!)
  --ignoreCase, -i    be case insensitive
  --ignoreStyle, -y   be style insensitive
  --ext:EX1|EX2|...   only search the files with the given extension(s)
  --nocolor           output will be given without any colours.
  --verbose           be verbose: list every processed file
  --help, -h          shows this help
  --version, -v       shows the version
"""

type
  TOption = enum 
    optFind, optReplace, optPeg, optRegex, optRecursive, optConfirm, optStdin,
    optWord, optIgnoreCase, optIgnoreStyle, optVerbose
  TOptions = set[TOption]
  TConfirmEnum = enum 
    ceAbort, ceYes, ceAll, ceNo, ceNone
    
var
  filenames: seq[string] = @[]
  pattern = ""
  replacement = ""
  extensions: seq[string] = @[]
  options: TOptions = {optRegex}
  useWriteStyled = true

proc ask(msg: string): string =
  stdout.write(msg)
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

proc countLines(s: string, first, last: int): int = 
  var i = first
  while i <= last:
    if s[i] == '\13': 
      inc result
      if i < last and s[i+1] == '\10': inc(i)
    elif s[i] == '\10': 
      inc result
    inc i

proc beforePattern(s: string, first: int): int = 
  result = first-1
  while result >= 0:
    if s[result] in NewLines: break
    dec(result)
  inc(result)

proc afterPattern(s: string, last: int): int = 
  result = last+1
  while result < s.len:
    if s[result] in NewLines: break
    inc(result)
  dec(result)

proc writeColored(s: string) =
  if useWriteStyled:
    terminal.writeStyled(s, {styleUnderscore, styleBright})
  else:
    stdout.write(s)

proc highlight(s, match, repl: string, t: tuple[first, last: int],
               line: int, showRepl: bool) = 
  const alignment = 6
  stdout.write(line.`$`.align(alignment), ": ")
  var x = beforePattern(s, t.first)
  var y = afterPattern(s, t.last)
  for i in x .. t.first-1: stdout.write(s[i])
  writeColored(match)
  for i in t.last+1 .. y: stdout.write(s[i])
  stdout.write("\n")
  if showRepl:
    stdout.write(spaces(alignment-1), "-> ")
    for i in x .. t.first-1: stdout.write(s[i])
    writeColored(repl)
    for i in t.last+1 .. y: stdout.write(s[i])
    stdout.write("\n")

proc processFile(filename: string) =
  var filenameShown = false
  template beforeHighlight =
    if not filenameShown and optVerbose notin options: 
      stdout.writeln(filename)
      filenameShown = true
  
  var buffer: string
  try:
    buffer = system.readFile(filename)
  except IOError: 
    echo "cannot open file: ", filename
    return
  if optVerbose in options: stdout.writeln(filename)
  var pegp: TPeg
  var rep: Regex
  var result: string

  if optRegex in options:
    if {optIgnoreCase, optIgnoreStyle} * options != {}:
      rep = re(pattern, {reExtended, reIgnoreCase})
    else:
      rep = re(pattern)
  else:
    pegp = peg(pattern)
    
  if optReplace in options:
    result = newStringOfCap(buffer.len)
    
  var line = 1
  var i = 0
  var matches: array[0..re.MaxSubpatterns-1, string]
  for j in 0..high(matches): matches[j] = ""
  var reallyReplace = true
  while i < buffer.len:
    var t: tuple[first, last: int]
    if optRegex notin options:
      t = findBounds(buffer, pegp, matches, i)
    else:
      t = findBounds(buffer, rep, matches, i)
    if t.first <= 0: break
    inc(line, countLines(buffer, i, t.first-1))
    
    var wholeMatch = buffer.substr(t.first, t.last)
    
    beforeHighlight()
    if optReplace notin options: 
      highlight(buffer, wholeMatch, "", t, line, showRepl=false)
    else:
      var r: string
      if optRegex notin options:
        r = replace(wholeMatch, pegp, replacement % matches)
      else: 
        r = replace(wholeMatch, rep, replacement % matches)
      if optConfirm in options: 
        highlight(buffer, wholeMatch, r, t, line, showRepl=true)
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
        highlight(buffer, wholeMatch, r, t, line, showRepl=reallyReplace)
      if reallyReplace:
        result.add(buffer.substr(i, t.first-1))
        result.add(r)
      else:
        result.add(buffer.substr(i, t.last))

    inc(line, countLines(buffer, t.first, t.last))
    i = t.last+1
  if optReplace in options:
    result.add(substr(buffer, i))
    var f: File
    if open(f, filename, fmWrite):
      f.write(result)
      f.close()
    else:
      quit "cannot open file for overwriting: " & filename

proc hasRightExt(filename: string, exts: seq[string]): bool =
  var y = splitFile(filename).ext.substr(1) # skip leading '.'
  for x in items(exts): 
    if os.cmpPaths(x, y) == 0: return true

proc styleInsensitive(s: string): string = 
  template addx: stmt = 
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

proc walker(dir: string) = 
  for kind, path in walkDir(dir):
    case kind
    of pcFile: 
      if extensions.len == 0 or path.hasRightExt(extensions):
        processFile(path)
    of pcDir: 
      if optRecursive in options:
        walker(path)
    else: discard
  if existsFile(dir): processFile(dir)

proc writeHelp() = 
  stdout.write(Usage)
  quit(0)

proc writeVersion() = 
  stdout.write(Version & "\n")
  quit(0)

proc checkOptions(subset: TOptions, a, b: string) =
  if subset <= options:
    quit("cannot specify both '$#' and '$#'" % [a, b])

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
  of cmdLongoption, cmdShortOption:
    case normalize(key)
    of "find", "f": incl(options, optFind)
    of "replace", "r": incl(options, optReplace)
    of "peg":
      excl(options, optRegex)
      incl(options, optPeg)
    of "re":
      incl(options, optRegex)
      excl(options, optPeg)
    of "recursive": incl(options, optRecursive)
    of "confirm": incl(options, optConfirm)
    of "stdin": incl(options, optStdin)
    of "word", "w": incl(options, optWord)
    of "ignorecase", "i": incl(options, optIgnoreCase)
    of "ignorestyle", "y": incl(options, optIgnoreStyle)
    of "ext": extensions = val.split('|')
    of "nocolor": useWriteStyled = false
    of "verbose": incl(options, optVerbose)
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
    else: writeHelp()
  of cmdEnd: assert(false) # cannot happen

when defined(posix):
  useWriteStyled = terminal.isatty(stdout)

checkOptions({optFind, optReplace}, "find", "replace")
checkOptions({optPeg, optRegex}, "peg", "re")
checkOptions({optIgnoreCase, optIgnoreStyle}, "ignore_case", "ignore_style")

if optStdin in options: 
  pattern = ask("pattern [ENTER to exit]: ")
  if isNil(pattern) or pattern.len == 0: quit(0)
  if optReplace in options:
    replacement = ask("replacement [supports $1, $# notations]: ")

if pattern.len == 0:
  writeHelp()
else: 
  if filenames.len == 0: 
    filenames.add(os.getCurrentDir())
  if optRegex notin options: 
    if optWord in options:
      pattern = r"(^ / !\letter)(" & pattern & r") !\letter"
    if optIgnoreStyle in options: 
      pattern = "\\y " & pattern
    elif optIgnoreCase in options:
      pattern = "\\i " & pattern
  else:
    if optIgnoreStyle in options: 
      pattern = styleInsensitive(pattern)
    if optWord in options:
      pattern = r"\b (:?" & pattern & r") \b"
  for f in items(filenames):
    walker(f)

