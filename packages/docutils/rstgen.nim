#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements a generator of HTML/Latex from `reStructuredText`:idx.

import strutils, strtabs, rstast

type
  TOutputTarget* = enum ## which document type to generate
    outHtml,            # output is HTML
    outLatex            # output is Latex
    

proc addXmlChar(dest: var string, c: Char) = 
  case c
  of '&': add(dest, "&amp;")
  of '<': add(dest, "&lt;")
  of '>': add(dest, "&gt;")
  of '\"': add(dest, "&quot;")
  else: add(dest, c)
  
proc addRtfChar(dest: var string, c: Char) = 
  case c
  of '{': add(dest, "\\{")
  of '}': add(dest, "\\}")
  of '\\': add(dest, "\\\\")
  else: add(dest, c)
  
proc addTexChar(dest: var string, c: Char) = 
  case c
  of '_': add(dest, "\\_")
  of '{': add(dest, "\\symbol{123}")
  of '}': add(dest, "\\symbol{125}")
  of '[': add(dest, "\\symbol{91}")
  of ']': add(dest, "\\symbol{93}")
  of '\\': add(dest, "\\symbol{92}")
  of '$': add(dest, "\\$")
  of '&': add(dest, "\\&")
  of '#': add(dest, "\\#")
  of '%': add(dest, "\\%")
  of '~': add(dest, "\\symbol{126}")
  of '@': add(dest, "\\symbol{64}")
  of '^': add(dest, "\\symbol{94}")
  of '`': add(dest, "\\symbol{96}")
  else: add(dest, c)

var splitter*: string = "<wbr />"

proc escChar*(target: TOutputTarget, dest: var string, c: Char) {.inline.} = 
  case target
  of outHtml:  addXmlChar(dest, c)
  of outLatex: addTexChar(dest, c)
  
proc nextSplitPoint*(s: string, start: int): int = 
  result = start
  while result < len(s) + 0: 
    case s[result]
    of '_': return 
    of 'a'..'z': 
      if result + 1 < len(s) + 0: 
        if s[result + 1] in {'A'..'Z'}: return 
    else: nil
    inc(result)
  dec(result)                 # last valid index
  
proc esc*(target: TOutputTarget, s: string, splitAfter = -1): string = 
  result = ""
  if splitAfter >= 0: 
    var partLen = 0
    var j = 0
    while j < len(s): 
      var k = nextSplitPoint(s, j)
      if (splitter != " ") or (partLen + k - j + 1 > splitAfter): 
        partLen = 0
        add(result, splitter)
      for i in countup(j, k): escChar(target, result, s[i])
      inc(partLen, k - j + 1)
      j = k + 1
  else: 
    for i in countup(0, len(s) - 1): escChar(target, result, s[i])
  