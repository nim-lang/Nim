#
#
#           Nimrod Grep Utility
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, parseopt, pegs, re, terminal

const
  Version = "0.7"
  Usage = "nimgrep - Nimrod Grep Utility Version " & version & """

  (c) 2011 Andreas Rumpf
Usage:
  nimgrep [options] [pattern] [replacement] (file/directory)*
Options:
  --find, -f          find the pattern (default)
  --replace, -r       replace the pattern
  --peg               pattern is a peg (default)
  --re                pattern is a regular expression; extended syntax for
                      the regular expression is always turned on
  --recursive         process directories recursively
  --confirm           confirm each occurence/replacement; there is a chance 
                      to abort any time without touching the file
  --stdin             read pattern from stdin (to avoid the shell's confusing
                      quoting rules)
  --word, -w          the pattern should have word boundaries
  --ignoreCase, -i    be case insensitive
  --ignoreStyle, -y   be style insensitive
  --ext:EX1|EX2|...   only search the files with the given extension(s)
  --help, -h          shows this help
  --version, -v       shows the version
"""

type
  TOption = enum 
    optFind, optReplace, optPeg, optRegex, optRecursive, optConfirm, optStdin,
    optWord, optIgnoreCase, optIgnoreStyle
  TOptions = set[TOption]
  TConfirmEnum = enum 
    ceAbort, ceYes, ceAll, ceNo, ceNone
    
var
  filenames: seq[string] = @[]
  pattern = ""
  replacement = ""
  extensions: seq[string] = @[]
  options: TOptions

proc ask(msg: string): string =
  stdout.write(msg)
  result = stdin.readline()

proc Confirm: TConfirmEnum = 
  while true:
    case normalize(ask("     [a]bort; [y]es, a[l]l, [n]o, non[e]: "))
    of "a", "abort": return ceAbort 
    of "y", "yes": return ceYes
    of "l", "all": return ceAll
    of "n", "no": return ceNo
    of "e", "none": return ceNone
    else: nil

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
    if s[result] in newlines: break
    dec(result)
  inc(result)

proc afterPattern(s: string, last: int): int = 
  result = last+1
  while result < s.len:
    if s[result] in newlines: break
    inc(result)
  dec(result)

proc highlight(s, match, repl: string, t: tuple[first, last: int],
               line: int, showRepl: bool) = 
  const alignment = 6
  stdout.write(line.`$`.align(alignment), ": ")
  var x = beforePattern(s, t.first)
  var y = afterPattern(s, t.last)
  for i in x .. t.first-1: stdout.write(s[i])
  terminal.WriteStyled(match, {styleUnderscore, styleBright})
  for i in t.last+1 .. y: stdout.write(s[i])
  stdout.write("\n")
  if showRepl:
    stdout.write(repeatChar(alignment-1), "-> ")
    for i in x .. t.first-1: stdout.write(s[i])
    terminal.WriteStyled(repl, {styleUnderscore, styleBright})
    for i in t.last+1 .. y: stdout.write(s[i])
    stdout.write("\n")

proc processFile(filename: string) = 
  var buffer = system.readFile(filename)
  if isNil(buffer): quit("cannot open file: " & filename)
  stdout.writeln(filename)
  var pegp: TPeg
  var rep: TRegex
  var result: string

  if optRegex in options:
    if optIgnoreCase in options:
      rep = re(pattern, {reExtended, reIgnoreCase})
    else:
      rep = re(pattern)
  else:
    pegp = peg(pattern)
    
  if optReplace in options:
    result = newString(buffer.len)
    setLen(result, 0)
    
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
    
    var wholeMatch = buffer.copy(t.first, t.last)
    
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
        case Confirm()
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
        result.add(buffer.copy(i, t.first-1))
        result.add(r)
      else:
        result.add(buffer.copy(i, t.last))

    inc(line, countLines(buffer, t.first, t.last))
    i = t.last+1
  if optReplace in options:
    result.add(copy(buffer, i))
    var f: TFile
    if open(f, filename, fmWrite):
      f.write(result)
      f.close()
    else:
      quit "cannot open file for overwriting: " & filename

proc hasRightExt(filename: string, exts: seq[string]): bool =
  var y = splitFile(filename).ext.copy(1) # skip leading '.'
  for x in items(exts): 
    if os.cmpPaths(x, y) == 0: return true

proc walker(dir: string) = 
  var isDir = false
  for kind, path in walkDir(dir):
    isDir = true
    case kind
    of pcFile: 
      if extensions.len == 0 or path.hasRightExt(extensions):
        processFile(path)
    of pcDir: 
      if optRecursive in options:
        walker(path)
    else: nil
  if not isDir: processFile(dir)

proc writeHelp() = quit(Usage)
proc writeVersion() = quit(Version)

proc checkOptions(subset: TOptions, a, b: string) =
  if subset <= options:
    quit("cannot specify both '$#' and '$#'" % [a, b])

for kind, key, val in getopt():
  case kind
  of cmdArgument:
    if options.contains(optStdIn): 
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
    of "replace", "r": incl(options, optReplace)
    of "peg": incl(options, optPeg)
    of "re": incl(options, optRegex)
    of "recursive": incl(options, optRecursive)
    of "confirm": incl(options, optConfirm)
    of "stdin": incl(options, optStdin)
    of "word", "w": incl(options, optWord)
    of "ignorecase", "i": incl(options, optIgnoreCase)
    of "ignorestyle", "y": incl(options, optIgnoreStyle)
    of "ext": extensions = val.split('|')
    of "help", "h": writeHelp()
    of "version", "v": writeVersion()
    else: writeHelp()
  of cmdEnd: assert(false) # cannot happen

checkOptions({optFind, optReplace}, "find", "replace")
checkOptions({optPeg, optRegex}, "peg", "re")
checkOptions({optIgnoreCase, optIgnoreStyle}, "ignore_case", "ignore_style")
checkOptions({optIgnoreCase, optPeg}, "ignore_case", "peg")

if optStdin in options: 
  pattern = ask("pattern [ENTER to exit]: ")
  if IsNil(pattern) or pattern.len == 0: quit(0)
  if optReplace in options:
    replacement = ask("replacement [supports $1, $# notations]: ")

if pattern.len == 0:
  writeHelp()
else: 
  if filenames.len == 0: 
    filenames.add(os.getCurrentDir())
  if optRegex notin options: 
    if optIgnoreStyle in options: 
      pattern = "\\y " & pattern
    elif optIgnoreCase in options:
      pattern = "\\i " & pattern
    if optWord in options:
      pattern = r"(&\letter? / ^ )(" & pattern & r") !\letter"
  else:
    if optIgnoreStyle in options: 
      quit "ignorestyle not supported for regular expressions"
    if optWord in options:
      pattern = r"\b (:?" & pattern & r") \b"
  for f in items(filenames):
    walker(f)

