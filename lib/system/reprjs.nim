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
    add result, "nil"
    return
  reprStrAux(result, s, s.len)

proc addSetElem(result: var string, elem: int, typ: PNimType) =
  # Dispatch each element to the correct repr proc
  case typ.kind
  of tyEnum: add result, reprEnum(elem, typ)
  of tyBool: add result, reprBool(bool(elem))
  of tyChar: add result, reprChar(chr(elem))
  of tyRange: addSetElem(result, elem, typ.base) # Note the base to advance toward the element type
  of tyInt..tyInt64, tyUInt8, tyUInt16: add result, reprInt(elem)
  else: # data corrupt --> inform the user
    add result, " (invalid data!)"

iterator SetKeys(s:int): int {.inline.} =
  # The type of s is a lie, it's expected to be a set.
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

proc reprSetAux(result: var string, s:int, typ: PNimType) {.asmNoStackFrame.}=
  add result, "{"
  var first : bool = true
  for el in SetKeys(s):
    if first:
      first  = false
    else:
      add result, ", "
    addSetElem(result,el,typ.base)
  #[
  Alternative:

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
      addSetElem(result,el,typ.base)]#
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

proc reprAux(result: var string, p: pointer, typ: PNimType, cl: var ReprClosure) 

proc reprArray(p: pointer, typ: PNimType, 
              cl: var ReprClosure):string {.compilerRtl.} =
  result = "["
  for i in 0 .. < typ.size:
    if i > 0: add result, ", "
    reprAux(result, p, typ.base, cl )
    # We know the actual pointer in js has a `_Idx` suffix, 
    # so we cheat and advance the pointer. 
    # If c can do pointer math we are allowd this, right?
    asm "`p`_Idx++;"

  add result, "]"

proc reprAux(result: var string, p: pointer, typ: PNimType, 
            cl: var ReprClosure) =
  if cl.recdepth == 0:
    add result, "..."
    return
  dec(cl.recdepth)
  case typ.kind
  of tyInt..tyInt64,tyUInt..tyUInt64:
    add result, reprInt(cast[ptr int](p)[])
  of tyChar:
    add result, reprChar(cast[ptr char](p)[])
  of tyBool:
    add result, reprBool(cast[ptr bool](p)[])
  of tyFloat..tyFloat128:
    add result, reprFloat(cast[ptr float](p)[])
  of tyString:
    add result, reprStr(cast[ptr string](p)[])
  of tyEnum, tyOrdinal:
    add result, reprEnum(cast[ptr int](p)[],typ)
  of tySet:
    add result, reprSet(cast[ptr int](p)[],typ)
  of tyArray:
    add result, reprArray(p,typ,cl)
  else:
    add result, "(invalid data!)"
  inc(cl.recdepth)

proc reprAny(p: pointer, typ: PNimType): string {.compilerRtl.}=
  var
    cl: ReprClosure
  initReprClosure(cl)
  result = ""
  if typ.kind in {tyObject, tyTuple, tyArray, tyArrayConstr, tySet}:
    reprAux(result, p, typ, cl)
  else:
    var p = p
    reprAux(result, addr(p), typ, cl)
  add result, "\n"

#[]

proc reprAux(result: var string, p: pointer, typ: PNimType,
              cl: var ReprClosure) {.benign.}

  proc reprAux(result: var string, p: pointer, typ: PNimType,
               cl: var ReprClosure) =
    if cl.recdepth == 0:
      add result, "..."
      return
    dec(cl.recdepth)
    case typ.kind
    of tyArray, tyArrayConstr: reprArray(result, p, typ, cl)
    #[
    of tySet: reprSetAux(result, p, typ)
    of tyArray, tyArrayConstr: reprArray(result, p, typ, cl)
    of tyTuple: reprRecord(result, p, typ, cl)
    of tyObject:
      var t = cast[ptr PNimType](p)[]
      reprRecord(result, p, t, cl)
    of tyRef, tyPtr:
      sysAssert(p != nil, "reprAux")
      if cast[PPointer](p)[] == nil: add result, "nil"
      else: reprRef(result, cast[PPointer](p)[], typ, cl)
    of tySequence:
      reprSequence(result, cast[PPointer](p)[], typ, cl)
    of tyInt: add result, $(cast[ptr int](p)[])
    of tyInt8: add result, $int(cast[ptr int8](p)[])
    of tyInt16: add result, $int(cast[ptr int16](p)[])
    of tyInt32: add result, $int(cast[ptr int32](p)[])
    of tyInt64: add result, $(cast[ptr int64](p)[])
    of tyUInt: add result, $(cast[ptr uint](p)[])
    of tyUInt8: add result, $(cast[ptr uint8](p)[])
    of tyUInt16: add result, $(cast[ptr uint16](p)[])
    of tyUInt32: add result, $(cast[ptr uint32](p)[])
    of tyUInt64: add result, $(cast[ptr uint64](p)[])

    of tyFloat: add result, $(cast[ptr float](p)[])
    of tyFloat32: add result, $(cast[ptr float32](p)[])
    of tyFloat64: add result, $(cast[ptr float64](p)[])
    of tyEnum: add result, reprEnum(getInt(p, typ.size), typ)
    of tyBool: add result, reprBool(cast[ptr bool](p)[])
    of tyChar: add result, reprChar(cast[ptr char](p)[])
    of tyString:
      let sp = cast[ptr string](p)
      reprStrAux(result, if sp[].isNil: nil else: sp[].cstring, sp[].len)
    of tyCString:
      let cs = cast[ptr cstring](p)[]
      if cs.isNil: add result, "nil"
      else: reprStrAux(result, cs, cs.len)
    of tyRange: reprAux(result, p, typ.base, cl)
    of tyProc, tyPointer:
      if cast[PPointer](p)[] == nil: add result, "nil"
      else: add result, reprPointer(cast[PPointer](p)[])
    ]#
    else:
      add result, "(invalid data!)"
    inc(cl.recdepth)
]#
