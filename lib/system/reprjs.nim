#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

proc reprInt(x: int64): string {.compilerproc.} = return $x
proc reprFloat(x: float): string {.compilerproc.} = 
  # Js toString doesn't differentiate between 1.0 and 1,
  # but we do.
  if $x == $(x.int): $x & ".0"
  else: $x

proc reprPointer(p: int): string {.compilerproc.} = $p
  # Do we need to generate the full 8bytes ? In js a pointer is an int anyway

proc reprBool(x: bool): string {.compilerRtl.} =
  if x: result = "true"
  else: result = "false"

#[
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
]#

proc isUndefined[T](x: T): bool {.inline.} = {.emit: "`result`= `x` === undefined;"}

proc reprEnum(e: int, typ: PNimType): string {.compilerRtl.} =
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
    of '\\': add result, "\\\\"
    of '\10': add result, "\\10\"\n\""
    of '\128' .. '\255', '\0'..'\9', '\11'..'\31':
      add result, "\\" & reprInt(ord(c))
    else:
      add result, reprInt(ord(c)) # Not sure about this.
  add result, "\""

proc reprStr(s: string): string {.compilerRtl.} =
  result = ""
  if cast[pointer](s).isnil:
    # Handle nil strings here because they don't have a length field in js
    # TODO: check for null/undefined before generating call to length in js
    # Also: c backend repr of a nil string is <pointer>"", but repr of an 
    # array of string that is not initialized is [nil, nil, ...]
    add result, "nil"
    return
  reprStrAux(result, s, s.len)

proc addSetElem(result: var string, elem: int, typ: PNimType) =
  # Dispatch each set element to the correct repr<Type> proc
  case typ.kind
  of tyEnum: add result, reprEnum(elem, typ)
  of tyBool: add result, reprBool(bool(elem))
  of tyChar: add result, reprChar(chr(elem))
  of tyRange: addSetElem(result, elem, typ.base) # Note the base to advance towards the element type
  of tyInt..tyInt64, tyUInt8, tyUInt16: add result, reprInt(elem)
  else: # data corrupt --> inform the user
    add result, " (invalid data!)"

iterator SetKeys(s: int): int {.inline.} =
  # The type of s is a lie, but it's expected to be a set.
  # This means every key has to be a positive integer.
  # Iterate over the JS object representing a set 
  # and returns the keys as int.
  var len: int
  var yieldRes : int
  var i : int = 0
  asm """
  var setObjKeys = Object.getOwnPropertyNames(`s`);
  `len` = setObjKeys.length
  """
  while i<len:
    asm "`yieldRes` = parseInt(setObjKeys[`i`],10);\n"
    yield yieldRes
    inc i

iterator ArrayItems(s: int): int {.inline.} =
  # The type of s is a lie, but it's expected to be an array.
  # This means every key has to be a positive integer.
  # Iterate over the JS array items,
  # and returns the element as a (fake) int.
  if not cast[pointer](s).isnil:
    var len: int
    var yieldRes : int
    var i : int = 0
    asm """
    `len` = `s`.length;
    """
    while i<len:
      asm "`yieldRes` = `s`[`i`];\n"
      yield yieldRes
      inc i

proc reprSetAux(result: var string, s: int, typ: PNimType) =
  add result, "{"
  var first : bool = true
  for el in SetKeys(s):
    if first:
      first  = false
    else:
      add result, ", "
    addSetElem(result,el,typ.base)
  #[
  Alternative without iterator:

  let fieldcount: int = 0 # we cheat using asm to set it to its value.
  var el : int
  asm """
  var setObjKeys = Object.getOwnPropertyNames(`s`);
  `fieldcount` = setObjKeys.length
  """
  case fieldcount
  of 0: discard
  of 1:
    asm "`el` = parseInt(setObjKeys[0],10);\n"
    addSetElem(result,el,typ.base)
  of 2:
    asm "`el` = parseInt(setObjKeys[0],10);\n"
    addSetElem(result,el,typ.base)
    add result, ", "      
    asm "`el` = parseInt(setObjKeys[1],10);\n"
    addSetElem(result,el,typ.base)
  else:
    for i in 0 .. < fieldcount:
      asm "`el` = parseInt(setObjKeys[`i`],10);\n"
      if i != fieldcount-1:
        add result, ", "
      addSetElem(result,el,typ.base)
  ]#
  add result, "}"

proc reprSet(e: int, typ: PNimType): string {.compilerRtl.} =
  result = ""
  reprSetAux(result, e, typ)

type
  ReprClosure {.final.} = object
    recdepth: int       # do not recurse endlessly
    indent: int         # indentation

proc initReprClosure(cl: var ReprClosure) =
  cl.recdepth = -1      # default is to display everything!
  cl.indent = 0

proc reprBreak(result: var string, cl: ReprClosure) =
  add result, "\n"
  for i in 0..cl.indent-1: add result, ' '

proc reprAux(result: var string, p: int, typ: PNimType, cl: var ReprClosure) 

proc reprArray(a: int, typ: PNimType, 
              cl: var ReprClosure):string {.compilerRtl.} =
  
  if typ.kind == tySequence and cast[pointer](a).isnil: return "nil"

  result = if typ.kind == tySequence: "@[" else: "["
  # We prepend @ to seq, the C backend prepends the pointer to the seq
  var first : bool = true
  for el in ArrayItems(a):
    if first:
      first  = false
    else:
      add result, ", "
    reprAux(result, el, typ.base, cl )  
  add result, "]"

proc reprAux(result: var string, p: int, typ: PNimType, 
            cl: var ReprClosure) =
  if cl.recdepth == 0:
    add result, "..."
    return
  dec(cl.recdepth)
  case typ.kind
  of tyInt..tyInt64,tyUInt..tyUInt64:
    add result, reprInt(p)    
  of tyChar:
    add result, reprChar(cast[char](p))    
  of tyBool:
    add result, reprBool(cast[bool](p))    
  of tyFloat..tyFloat128:
    add result, reprFloat(cast[float](p))
  of tyString:
    # do we want same behaviour as C?
    add result, reprStr(cast[string](p))
  of tyCString:
    if cast[cstring](p).isnil:
      add result, "nil"
    else:
      reprStrAux(result,cast[cstring](p),cast[cstring](p).len)
  of tyEnum, tyOrdinal:
    add result, reprEnum(p,typ)
  of tySet:
    add result, reprSet(p,typ)
  of tyArray,tyArrayConstr,tySequence:
    add result, reprArray(p,typ,cl)
  else:
    add result, "(invalid data!)"
  inc(cl.recdepth)

proc reprAny(p: int, typ: PNimType): string {.compilerRtl.}=
  var cl: ReprClosure
  initReprClosure(cl)
  result = ""
  reprAux(result, p, typ, cl)
  add result, "\n"
