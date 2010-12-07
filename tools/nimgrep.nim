#
#
#           Nimrod Grep Utility
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import
  os, strutils, parseopt, pegs, re, terminal

const
  Usage = """
Usage: nimgrep [options] [pattern] [files/directory]
Options:
  --find, -f          find the pattern (default)
  --replace, -r       replace the pattern
  --peg               pattern is a peg (default)
  --re                pattern is a regular expression
  --recursive         process directories recursively
  --confirm           confirm each occurence/replacement; there is a chance 
                      to abort any time without touching the file(s)
  --stdin             read pattern from stdin (to avoid the shell's confusing
                      quoting rules)
  --word, -w          the pattern should have word boundaries
  --ignore_case, -i   be case insensitive
  --ignore_style, -y  be style insensitive
"""

type
  TOption = enum 
    optFind, optReplace, optPeg, optRegex, optRecursive, optConfirm, optStdin,
    optWord, optIgnoreCase, optIgnoreStyle
  TOptions = set[TOption]
  TConfirmEnum = enum 
    ceAbort, ceYes, ceAll, ceNo, ceNone
    
var
  filename = ""
  pattern = ""
  replacement = ""
  options: TOptions

proc ask(msg: string): string =
  stdout.write(msg)
  result = stdin.readline()

proc Confirm: TConfirmEnum = 
  while true:
    case normalize(ask("[a]bort; [y]es, a[l]l, [n]o, non[e]: "))
    of "a", "abort": return ceAbort 
    of "y", "yes": return ceYes
    of "l", "all": return ceAll
    of "n", "no": return ceNo
    of "e", "none": return ceNone
    else: nil

proc highlight(a, b, c: string) = 
  stdout.write(a)
  terminal.WriteStyled(b)
  stdout.writeln(c)

proc countLines(s: string, first = 0, last = s.high): int = 
  var i = first
  while i <= last:
    if s[i] == '\13': 
      inc result
      if i < last and s[i+1] == '\10': inc(i)
    elif s[i] == '\10': 
      inc result
    inc i

proc processFile(filename: string) = 
  var buffer = system.readFile(filename)
  if isNil(buffer): quit("cannot open file: " & filename)
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
  var matches: array[0..re.MaxSubpatterns-1. string]
  var reallyReplace = true
  while i < buffer.len:
    var t: tuple[first, last: int]
    if optRegex in options:
      quit "to implement"
    else:
      t = findBounds(buffer, pegp, matches, i)

    if t.first <= 0: break
    inc(line, countLines(buffer, i, t.first-1))
    
    var wholeMatch = buffer.copy(t.first, t.last)
    echo "line ", line, ": ", wholeMatch
    
    if optReplace in options: 
      var r = replace(wholeMatch, pegp, replacement)
      
      if optConfirm in options: 
        case Confirm()
        of ceAbort:
        of ceYes:
        of ceAll: 
          reallyReplace = true
        of ceNo:
          reallyReplace = false
        of ceNone:
          reallyReplace = false
      if reallyReplace:
        

    inc(line, countLines(buffer, t.first, t.last))
    
    i = t.last+1
    

proc walker(dir: string) = 
  for kind, path in walkDir(dir):
    case kind
    of pcFile: processFile(path)
    of pcDirectory: 
      if optRecursive in options:
        walker(path)
    else: nil

proc writeHelp() = quit(Usage)
proc writeVersion() = quit("1.0")

proc checkOptions(subset: TOptions, a, b: string) =
  if subset <= options:
    quit("cannot specify both '$#' and '$#'" % [a, b])

for kind, key, val in getopt():
  case kind
  of cmdArgument:
    if options.contains(optStdIn): 
      filename = key
    elif pattern.len == 0: 
      pattern = key
    elif options.contains(optReplace) and replacement.len == 0:
      replacement = key
    else:
      filename = key
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
  if filename.len == 0: filename = os.getCurrentDir()
  walker(filename)

