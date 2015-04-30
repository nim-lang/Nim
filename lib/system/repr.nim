#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# The generic ``repr`` procedure. It is an invaluable debugging tool.

when not defined(useNimRtl):
  proc reprAny(p: pointer, typ: PNimType): string {.compilerRtl, gcsafe.}

proc reprInt(x: int64): string {.compilerproc.} = return $x
proc reprFloat(x: float): string {.compilerproc.} = return $x

proc reprPointer(x: pointer): string {.compilerproc.} =
  var buf: array [0..59, char]
  discard c_sprintf(buf, "%p", x)
  return $buf

proc `$`(x: uint64): string =
  var buf: array [0..59, char]
  discard c_sprintf(buf, "%llu", x)
  return $buf

proc reprStrAux(result: var string, s: string) =
  if cast[pointer](s) == nil:
    add result, "nil"
    return
  add result, reprPointer(cast[pointer](s)) & "\""
  for i in 0.. <s.len:
    let c = s[i]
    case c
    of '"': add result, "\\\""
    of '\\': add result, "\\\\" # BUGFIX: forgotten
    of '\10': add result, "\\10\"\n\"" # " \n " # better readability
    of '\128' .. '\255', '\0'..'\9', '\11'..'\31':
      add result, "\\" & reprInt(ord(c))
    else:
      result.add(c)
  add result, "\""

proc reprStr(s: string): string {.compilerRtl.} =
  result = ""
  reprStrAux(result, s)

proc reprBool(x: bool): string {.compilerRtl.} =
  if x: result = "true"
  else: result = "false"

proc reprChar(x: char): string {.compilerRtl.} =
  result = "\'"
  case x
  of '"': add result, "\\\""
  of '\\': add result, "\\\\"
  of '\128' .. '\255', '\0'..'\31': add result, "\\" & reprInt(ord(x))
  else: add result, x
  add result, "\'"

proc reprEnum(e: int, typ: PNimType): string {.compilerRtl.} =
  # we read an 'int' but this may have been too large, so mask the other bits:
  let e = if typ.size == 1: e and 0xff
          elif typ.size == 2: e and 0xffff
          else: e
  # XXX we need a proper narrowing based on signedness here
  #e and ((1 shl (typ.size*8)) - 1)
  if ntfEnumHole notin typ.flags:
    if e <% typ.node.len:
      return $typ.node.sons[e].name
  else:
    # ugh we need a slow linear search:
    var n = typ.node
    var s = n.sons
    for i in 0 .. n.len-1:
      if s[i].offset == e: return $s[i].name
  result = $e & " (invalid data!)"

type
  PByteArray = ptr array[0.. 0xffff, int8]

proc addSetElem(result: var string, elem: int, typ: PNimType) {.benign.} =
  case typ.kind
  of tyEnum: add result, reprEnum(elem, typ)
  of tyBool: add result, reprBool(bool(elem))
  of tyChar: add result, reprChar(chr(elem))
  of tyRange: addSetElem(result, elem, typ.base)
  of tyInt..tyInt64, tyUInt8, tyUInt16: add result, reprInt(elem)
  else: # data corrupt --> inform the user
    add result, " (invalid data!)"

proc reprSetAux(result: var string, p: pointer, typ: PNimType) =
  # "typ.slots.len" field is for sets the "first" field
  var elemCounter = 0  # we need this flag for adding the comma at
                       # the right places
  add result, "{"
  var u: int64
  case typ.size
  of 1: u = ze64(cast[ptr int8](p)[])
  of 2: u = ze64(cast[ptr int16](p)[])
  of 4: u = ze64(cast[ptr int32](p)[])
  of 8: u = cast[ptr int64](p)[]
  else:
    var a = cast[PByteArray](p)
    for i in 0 .. typ.size*8-1:
      if (ze(a[i div 8]) and (1 shl (i mod 8))) != 0:
        if elemCounter > 0: add result, ", "
        addSetElem(result, i+typ.node.len, typ.base)
        inc(elemCounter)
  if typ.size <= 8:
    for i in 0..sizeof(int64)*8-1:
      if (u and (1'i64 shl int64(i))) != 0'i64:
        if elemCounter > 0: add result, ", "
        addSetElem(result, i+typ.node.len, typ.base)
        inc(elemCounter)
  add result, "}"

proc reprSet(p: pointer, typ: PNimType): string {.compilerRtl.} =
  result = ""
  reprSetAux(result, p, typ)

type
  TReprClosure {.final.} = object # we cannot use a global variable here
                                  # as this wouldn't be thread-safe
    when declared(TCellSet):
      marked: TCellSet
    recdepth: int       # do not recurse endlessly
    indent: int         # indentation

when not defined(useNimRtl):
  proc initReprClosure(cl: var TReprClosure) =
    # Important: cellsets does not lock the heap when doing allocations! We
    # have to do it here ...
    when hasThreadSupport and hasSharedHeap and declared(heapLock):
      AcquireSys(HeapLock)
    when declared(TCellSet):
      init(cl.marked)
    cl.recdepth = -1      # default is to display everything!
    cl.indent = 0

  proc deinitReprClosure(cl: var TReprClosure) =
    when declared(TCellSet): deinit(cl.marked)
    when hasThreadSupport and hasSharedHeap and declared(heapLock): 
      ReleaseSys(HeapLock)

  proc reprBreak(result: var string, cl: TReprClosure) =
    add result, "\n"
    for i in 0..cl.indent-1: add result, ' '

  proc reprAux(result: var string, p: pointer, typ: PNimType,
               cl: var TReprClosure) {.benign.}

  proc reprArray(result: var string, p: pointer, typ: PNimType,
                 cl: var TReprClosure) =
    add result, "["
    var bs = typ.base.size
    for i in 0..typ.size div bs - 1:
      if i > 0: add result, ", "
      reprAux(result, cast[pointer](cast[ByteAddress](p) + i*bs), typ.base, cl)
    add result, "]"

  proc reprSequence(result: var string, p: pointer, typ: PNimType,
                    cl: var TReprClosure) =
    if p == nil:
      add result, "nil"
      return
    result.add(reprPointer(p) & "[")
    var bs = typ.base.size
    for i in 0..cast[PGenericSeq](p).len-1:
      if i > 0: add result, ", "
      reprAux(result, cast[pointer](cast[ByteAddress](p) + GenericSeqSize + i*bs),
              typ.base, cl)
    add result, "]"

  proc reprRecordAux(result: var string, p: pointer, n: ptr TNimNode,
                     cl: var TReprClosure) {.benign.} =
    case n.kind
    of nkNone: sysAssert(false, "reprRecordAux")
    of nkSlot:
      add result, $n.name
      add result, " = "
      reprAux(result, cast[pointer](cast[ByteAddress](p) + n.offset), n.typ, cl)
    of nkList:
      for i in 0..n.len-1:
        if i > 0: add result, ",\n"
        reprRecordAux(result, p, n.sons[i], cl)
    of nkCase:
      var m = selectBranch(p, n)
      reprAux(result, cast[pointer](cast[ByteAddress](p) + n.offset), n.typ, cl)
      if m != nil: reprRecordAux(result, p, m, cl)

  proc reprRecord(result: var string, p: pointer, typ: PNimType,
                  cl: var TReprClosure) =
    add result, "["
    let oldLen = result.len
    reprRecordAux(result, p, typ.node, cl)
    if typ.base != nil: 
      if oldLen != result.len: add result, ",\n"
      reprRecordAux(result, p, typ.base.node, cl)
    add result, "]"

  proc reprRef(result: var string, p: pointer, typ: PNimType,
               cl: var TReprClosure) =
    # we know that p is not nil here:
    when declared(TCellSet):
      when defined(boehmGC) or defined(nogc):
        var cell = cast[PCell](p)
      else:
        var cell = usrToCell(p)
      add result, "ref " & reprPointer(p)
      if cell notin cl.marked:
        # only the address is shown:
        incl(cl.marked, cell)
        add result, " --> "
        reprAux(result, p, typ.base, cl)

  proc reprAux(result: var string, p: pointer, typ: PNimType,
               cl: var TReprClosure) =
    if cl.recdepth == 0:
      add result, "..."
      return
    dec(cl.recdepth)
    case typ.kind
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
    of tyUInt8: add result, $ze(cast[ptr int8](p)[])
    of tyUInt16: add result, $ze(cast[ptr int16](p)[])
    
    of tyFloat: add result, $(cast[ptr float](p)[])
    of tyFloat32: add result, $(cast[ptr float32](p)[])
    of tyFloat64: add result, $(cast[ptr float64](p)[])
    of tyEnum: add result, reprEnum(cast[ptr int](p)[], typ)
    of tyBool: add result, reprBool(cast[ptr bool](p)[])
    of tyChar: add result, reprChar(cast[ptr char](p)[])
    of tyString: reprStrAux(result, cast[ptr string](p)[])
    of tyCString: reprStrAux(result, $(cast[ptr cstring](p)[]))
    of tyRange: reprAux(result, p, typ.base, cl)
    of tyProc, tyPointer:
      if cast[PPointer](p)[] == nil: add result, "nil"
      else: add result, reprPointer(cast[PPointer](p)[])
    else:
      add result, "(invalid data!)"
    inc(cl.recdepth)

proc reprOpenArray(p: pointer, length: int, elemtyp: PNimType): string {.
                   compilerRtl.} =
  var
    cl: TReprClosure
  initReprClosure(cl)
  result = "["
  var bs = elemtyp.size
  for i in 0..length - 1:
    if i > 0: add result, ", "
    reprAux(result, cast[pointer](cast[ByteAddress](p) + i*bs), elemtyp, cl)
  add result, "]"
  deinitReprClosure(cl)

when not defined(useNimRtl):
  proc reprAny(p: pointer, typ: PNimType): string =
    var
      cl: TReprClosure
    initReprClosure(cl)
    result = ""
    if typ.kind in {tyObject, tyTuple, tyArray, tyArrayConstr, tySet}:
      reprAux(result, p, typ, cl)
    else:
      var p = p
      reprAux(result, addr(p), typ, cl)
    add result, "\n"
    deinitReprClosure(cl)

