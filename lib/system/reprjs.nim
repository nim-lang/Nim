#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc reprInt(x: int64): string {.compilerproc.} = return $x
proc reprFloat(x: float): string {.compilerproc.} = return $x

proc reprBool(x: bool): string {.compilerRtl.} =
  if x: result = "true"
  else: result = "false"

proc `$`(x: uint64): string =
  if x == 0:
    result = "0"
  else:
    var buf: array[60, char]
    var i = 0
    var n = x
    while n != 0:
      let nn = n div 10'u64
      buf[i] = char(n - 10'u64 * nn + ord('0'))
      inc i
      n = nn

    let half = i div 2
    # Reverse
    for t in 0 .. < half: swap(buf[t], buf[i-t-1])
    result = $buf

proc isUndefined[T](x:T):bool {.inline.} = {.emit: "`result`= `x` === undefined;"}

proc reprEnum(e: int, typ: PNimType): string {.compilerRtl.} =
  # CHECKME: revert to c-like behaviour? (offsets and linear search)
  if not typ.node.sons[e].isUndefined :
    $typ.node.sons[e].name
  else:
    $e & " (invalid data!)"
  
proc reprChar(x: char): string {.compilerRtl.} =
  result = "\'"
  case x
  of '"': add result, "\\\""
  of '\\': add result, "\\\\"
  of '\128' .. '\255', '\0'..'\31': add result, "\\" & reprInt(ord(x))
  else: add result, x
  add result, "\'"

proc reprStrAux(result: var string, s: cstring; len: int) =
  add result, "\""
  for i in 0.. <len:
    let c = s[i]
    case c
    of '"': add result, "\\\""
    of '\\': add result, "\\\\" # BUGFIX: forgotten
    of '\10': add result, "\\10\"\n\"" # " \n " # better readability
    of '\128' .. '\255', '\0'..'\9', '\11'..'\31':
      add result, "\\" & reprInt(ord(c))
    else:
      add result, reprInt(ord(c)) # Stop the char being repr'd
  add result, "\""

proc reprStr(s: string): string {.compilerRtl.} =
  result = ""
  if cast[pointer](s).isnil:
    add result, "nil"
    return
  reprStrAux(result, s, s.len)