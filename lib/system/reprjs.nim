#
#
#            Nim's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# The generic ``repr`` procedure for the javascript backend.

proc reprInt(x: int64): string {.compilerproc.} = return $x
proc reprFloat(x: float): string {.compilerproc.} =
  # Js toString doesn't differentiate between 1.0 and 1,
  # but we do.
  if $x == $(x.int): $x & ".0"
  else: $x

proc reprPointer(p: pointer): string {.compilerproc.} =
  # Do we need to generate the full 8bytes ? In js a pointer is an int anyway
  var tmp: int
  {. emit: """
    if (`p`_Idx == null) {
      `tmp` = 0;
    } else {
      `tmp` = `p`_Idx;
    }
  """ .}
  result = $tmp

proc reprBool(x: bool): string {.compilerRtl.} =
  if x: result = "true"
  else: result = "false"

proc isUndefined[T](x: T): bool {.inline.} = {.emit: "`result` = `x` === undefined;"}

proc reprEnum(e: int, typ: PNimType): string {.compilerRtl.} =
  if not typ.node.sons[e].isUndefined:
    result = makeNimstrLit(typ.node.sons[e].name)
  else:
    result = $e & " (invalid data!)"

proc reprChar(x: char): string {.compilerRtl.} =
  result = "\'"
  case x
  of '"': add(result, "\\\"")
  of '\\': add(result, "\\\\")
  of '\127'..'\255', '\0'..'\31': add( result, "\\" & reprInt(ord(x)) )
  else: add(result, x)
  add(result, "\'")

proc reprStrAux(result: var string, s: cstring, len: int) =
  add(result, "\"")
  for i in 0 .. len-1:
    let c = s[i]
    case c
    of '"': add(result, "\\\"")
    of '\\': add(result, "\\\\")
    #of '\10': add(result, "\\10\"\n\"")
    of '\127'..'\255', '\0'..'\31':
      add(result, "\\" & reprInt(ord(c)))
    else:
      add(result, c)
  add(result, "\"")

proc reprStr(s: string): string {.compilerRtl.} =
  result = ""
  if cast[pointer](s).isNil:
    # Handle nil strings here because they don't have a length field in js
    # TODO: check for null/undefined before generating call to length in js?
    # Also: c backend repr of a nil string is <pointer>"", but repr of an
    # array of string that is not initialized is [nil, nil, ...] ??
    add(result, "nil")
  else:
    reprStrAux(result, s, s.len)

proc addSetElem(result: var string, elem: int, typ: PNimType) =
  # Dispatch each set element to the correct repr<Type> proc
  case typ.kind:
  of tyEnum: add(result, reprEnum(elem, typ))
  of tyBool: add(result, reprBool(bool(elem)))
  of tyChar: add(result, reprChar(chr(elem)))
  of tyRange: addSetElem(result, elem, typ.base) # Note the base to advance towards the element type
  of tyInt..tyInt64, tyUInt8, tyUInt16: add result, reprInt(elem)
  else: # data corrupt --> inform the user
    add(result, " (invalid data!)")

iterator setKeys(s: int): int {.inline.} =
  # The type of s is a lie, but it's expected to be a set.
  # Iterate over the JS object representing a set
  # and returns the keys as int.
  var len: int
  var yieldRes: int
  var i: int = 0
  {. emit: """
  var setObjKeys = Object.getOwnPropertyNames(`s`);
  `len` = setObjKeys.length;
  """ .}
  while i < len:
    {. emit: "`yieldRes` = parseInt(setObjKeys[`i`],10);\n" .}
    yield yieldRes
    inc i

proc reprSetAux(result: var string, s: int, typ: PNimType) =
  add(result, "{")
  var first: bool = true
  for el in setKeys(s):
    if first:
      first = false
    else:
      add(result, ", ")
    addSetElem(result, el, typ.base)
  add(result, "}")

proc reprSet(e: int, typ: PNimType): string {.compilerRtl.} =
  result = ""
  reprSetAux(result, e, typ)

type
  ReprClosure {.final.} = object
    recDepth: int       # do not recurse endlessly
    indent: int         # indentation

proc initReprClosure(cl: var ReprClosure) =
  cl.recDepth = -1 # default is to display everything!
  cl.indent = 0

proc reprAux(result: var string, p: pointer, typ: PNimType, cl: var ReprClosure)

proc reprArray(a: pointer, typ: PNimType,
              cl: var ReprClosure): string {.compilerRtl.} =
  var isNilArrayOrSeq: bool
  # isnil is not enough here as it would try to deref `a` without knowing what's inside
  {. emit: """
    if (`a` == null) {
      `isNilArrayOrSeq` = true;
    } else if (`a`[0] == null) {
      `isNilArrayOrSeq` = true;
    } else {
      `isNilArrayOrSeq` = false;
    };
    """ .}
  if typ.kind == tySequence and isNilArrayOrSeq:
    return "nil"

  # We prepend @ to seq, the C backend prepends the pointer to the seq.
  result = if typ.kind == tySequence: "@[" else: "["
  var len: int = 0
  var i: int = 0

  {. emit: "`len` = `a`.length;\n" .}
  var dereffed: pointer = a
  for i in 0 .. len-1:
    if i > 0 :
      add(result, ", ")
    # advance pointer and point to element at index
    {. emit: """
    `dereffed`_Idx = `i`;
    `dereffed` = `a`[`dereffed`_Idx];
    """ .}
    reprAux(result, dereffed, typ.base, cl)

  add(result, "]")

proc isPointedToNil(p: pointer): bool {.inline.}=
  {. emit: "if (`p` === null) {`result` = true};\n" .}

proc reprRef(result: var string, p: pointer, typ: PNimType,
          cl: var ReprClosure) =
  if p.isPointedToNil:
    add(result , "nil")
    return
  add( result, "ref " & reprPointer(p) )
  add(result, " --> ")
  if typ.base.kind != tyArray:
    {. emit: """
    if (`p` != null && `p`.length > 0) {
      `p` = `p`[`p`_Idx];
    }
    """ .}
  reprAux(result, p, typ.base, cl)

proc reprRecordAux(result: var string, o: pointer, typ: PNimType, cl: var ReprClosure) =
  add(result, "[")

  var first: bool = true
  var val: pointer = o
  if typ.node.len == 0:
    # if the object has only one field, len is 0  and sons is nil, the field is in node
    let key: cstring = typ.node.name
    add(result, $key & " = ")
    {. emit: "`val` = `o`[`key`];\n" .}
    reprAux(result, val, typ.node.typ, cl)
  else:
    # if the object has more than one field, sons is not nil and contains the fields.
    for i in 0 .. typ.node.len-1:
      if first: first = false
      else: add(result, ",\n")

      let key: cstring = typ.node.sons[i].name
      add(result, $key & " = ")
      {. emit: "`val` = `o`[`key`];\n" .} # access the field by name
      reprAux(result, val, typ.node.sons[i].typ, cl)
  add(result, "]")

proc reprRecord(o: pointer, typ: PNimType, cl: var ReprClosure): string {.compilerRtl.} =
  result = ""
  reprRecordAux(result, o, typ,cl)


proc reprJSONStringify(p: int): string {.compilerRtl.} =
  # As a last resort, use stringify
  # We use this for tyOpenArray, tyVarargs while genTypeInfo is not implemented
  var tmp: cstring
  {. emit: "`tmp` = JSON.stringify(`p`);\n" .}
  result = $tmp

proc reprAux(result: var string, p: pointer, typ: PNimType,
            cl: var ReprClosure) =
  if cl.recDepth == 0:
    add(result, "...")
    return
  dec(cl.recDepth)
  case typ.kind
  of tyInt..tyInt64, tyUInt..tyUInt64:
    add( result, reprInt(cast[int](p)) )
  of tyChar:
    add( result, reprChar(cast[char](p)) )
  of tyBool:
    add( result, reprBool(cast[bool](p)) )
  of tyFloat..tyFloat128:
    add( result, reprFloat(cast[float](p)) )
  of tyString:
    var fp: int
    {. emit: "`fp` = `p`;\n" .}
    if cast[string](fp).isNil:
      add(result, "nil")
    else:
      add( result, reprStr(cast[string](p)) )
  of tyCString:
    var fp: cstring
    {. emit: "`fp` = `p`;\n" .}
    if fp.isNil:
      add(result, "nil")
    else:
      reprStrAux(result, fp, fp.len)
  of tyEnum, tyOrdinal:
    var fp: int
    {. emit: "`fp` = `p`;\n" .}
    add(result, reprEnum(fp, typ))
  of tySet:
    var fp: int
    {. emit: "`fp` = `p`;\n" .}
    add(result, reprSet(fp, typ))
  of tyRange: reprAux(result, p, typ.base, cl)
  of tyObject, tyTuple:
    add(result, reprRecord(p, typ, cl))
  of tyArray, tyArrayConstr, tySequence:
    add(result, reprArray(p, typ, cl))
  of tyPointer:
    add(result, reprPointer(p))
  of tyPtr, tyRef:
    reprRef(result, p, typ, cl)
  of tyProc:
    if p.isPointedToNil:
      add(result, "nil")
    else:
      add(result, reprPointer(p))
  else:
    add( result, "(invalid data!)" & reprJsonStringify(cast[int](p)) )
  inc(cl.recDepth)

proc reprAny(p: pointer, typ: PNimType): string {.compilerRtl.} =
  var cl: ReprClosure
  initReprClosure(cl)
  result = ""
  reprAux(result, p, typ, cl)
  add(result, "\n")