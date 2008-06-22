# new implementation of regular expressions

type
  TRegexKind = enum 
    regNone,
    regChar, 
    regSet,
    regConc,
    regAlt,
    regStar,
    regPlus,
    regMN,
    regNewline
  
  TRegex = record
    case kind: TRegexKind
    of regChar: c: char
    of regSet: s: ref set[char]
    else: a, b: PRegEx
    
  PRegEx* = ref TRegEx

  TRegExFlag* = enum   ## Flags concerning the semantics of regular expressions
    reCaseInsensitive, ## case insensitive match 
    reStyleInsensitive ## style insensitive match
    
    
  TRegExFlags* = set[TRegExFlag]
    ## Flags concerning the semantics of regular expressions
    
proc raiseRegex(msg: string) {.noreturn.} = 
  var e: ref Exception
  new(e)
  e.msg = msg
  raise e

proc compileAux(i: int, s: string, r: PRegEx): int
    
proc compileBackslash(i: int, s: string, r: PRegEx): int = 
  var i = i
  inc(i)
  case s[i]
  of 'A'..'Z': 
  of 'a'..'z':
  of '0':
  of '1'..'9': 
  
  else:
    r.kind = regChar
    r.c = s[i]
  inc(i)
  result = i

proc compileAtom(i: int, s: string, r: PRegEx): int = 
  var i = i
  case s[i]
  of '[':
    inc(i)
    var inverse = s[i] == '^'
    if inverse: inc(i)
    r.kind = regSet
    new(r.s)
    while true: 
      case s[i]
      of '\\': i = compileBackslash(i, s, r)
      of ']': 
        inc(i)
        break
      of '\0': 
        raiseRegex("']' expected")
      elif s[i+1] == '-':
        var x = s[i]
        inc(i, 2)
        var y = s[i]
        inc(i)
        r.s = r.s + {x..y}
      else:
        incl(r.s, s[i])
        inc(i)
    if inverse:
      r.s = {'\0'..'\255'} - r.s
  of '\\':
    inc(i)
    i = compileBackslash(i, s, r)
  of '.':
    r.kind = regAny
    inc(i)
  of '(': 
    inc(i)
    i = compileAux(i, s, r)
    if s[i] = ')': inc(i)
    else: raiseRegex("')' expected")
  of '\0': nil # do nothing
  else:
    r.kind = regChar
    r.c = s[i]
    inc(i)
  result = i
    
proc compilePostfix(i: int, s: string, r: PRegEx): int = 
  var i = compileAtom(i, s, r)
  var a: PRegEx
  case s[i]
  of '*':
  of '+':
  of '?':
  else: nil

proc compileAux(i: int, s: string, r: PRegEx): int = 
  var i = i
  i = compileAtom(i, s, r)
  
  while s[i] != '\0':
    
  result = i
    
proc compile*(regex: string, flags: TRegExFlags = {}): PRegEx = 
  ## Compiles the string `regex` that represents a regular expression into 
  ## an internal data structure that can be used for matching.
  new(result)
  var i = compileAux(0, regex, result)
  if i < len(regex)-1:
    # not all characters used for the regular expression?
    raiseRegEx("invalid regular expression")
