import macros, macro_dsl, streams, streams_enh
from strutils import format

template newLenName(): stmt {.immediate.} =
  let lenName {.inject.} = ^("len"& $lenNames)
  inc(lenNames)

template defPacketImports*(): stmt {.immediate, dirty.} =
  import macros, macro_dsl, streams, streams_enh
  from strutils import format

proc `$`*[T](x: seq[T]): string =
  result = "[seq len="
  result.add($x.len)
  result.add ':'
  for i in 0.. <len(x):
    result.add "   "
    result.add($x[i])
  result.add ']'

macro defPacket*(typeNameN: expr, typeFields: expr): stmt {.immediate.} =
  result = newNimNode(nnkStmtList)
  let
    typeName = quoted2ident(typeNameN)
    packetID = ^"p"
    streamID = ^"s"
  var
    constructorParams = newNimNode(nnkFormalParams).und(typeName)
    constructor = newNimNode(nnkProcDef).und(
      postfix(^("new"& $typeName.ident), "*"),
      emptyNode(),
      emptyNode(),
      constructorParams,
      emptyNode(),
      emptyNode())
    pack = newNimNode(nnkProcDef).und(
      postfix(^"pack", "*"),
      emptyNode(),
      emptyNode(),
      newNimNode(nnkFormalParams).und(
        emptyNode(),   # : void
        newNimNode(nnkIdentDefs).und(
          packetID,    # p: var typeName
          newNimNode(nnkVarTy).und(typeName),
          emptyNode()),
        newNimNode(nnkIdentDefs).und(
          streamID,    # s: PStream
          ^"PStream",
          newNimNode(nnkNilLit))),
      emptyNode(),
      emptyNode())
    read = newNimNode(nnkProcDef).und(
      newIdentNode("read"& $typeName.ident).postfix("*"),
      emptyNode(),
      emptyNode(),
      newNimNode(nnkFormalParams).und(
        typeName,   #result type
        newNimNode(nnkIdentDefs).und(
          streamID, # s: PStream = nil
          ^"PStream",
          newNimNode(nnkNilLit))),
      emptyNode(),
      emptyNode())
    constructorBody = newNimNode(nnkStmtList)
    packBody = newNimNode(nnkStmtList)
    readBody = newNimNode(nnkStmtList)
    lenNames = 0
  for i in 0.. typeFields.len - 1:
    let
      name = typeFields[i][0]
      dotName = packetID.dot(name)
      resName = newIdentNode(!"result").dot(name)
    case typeFields[i][1].kind
    of nnkBracketExpr: #ex: paddedstring[32, '\0'], array[range, type]
      case $typeFields[i][1][0].ident
      of "paddedstring":
        let length = typeFields[i][1][1]
        let padChar = typeFields[i][1][2]
        packBody.add(newCall(
          "writePaddedStr", streamID, dotName, length, padChar))
        ## result.name = readPaddedStr(s, length, char)
        readBody.add(resName := newCall(
          "readPaddedStr", streamID, length, padChar))
        ## make the type a string
        typeFields[i] = newNimNode(nnkIdentDefs).und(
          name,
          ^"string",
          newNimNode(nnkEmpty))
      of "array":
        readBody.add(
          newNimNode(nnkDiscardStmt).und(
            newCall("readData", streamID, newNimNode(nnkAddr).und(resName), newCall("sizeof", resName))))
        packBody.add(
          newCall("writeData", streamID, newNimNode(nnkAddr).und(dotName), newCall("sizeof", dotName)))
      of "seq":
        ## let lenX = readInt16(s)
        newLenName()
        let
          item = ^"item"  ## item name in our iterators
          seqType = typeFields[i][1][1] ## type of seq
          readName = newIdentNode("read"& $seqType.ident)
        readBody.add(newNimNode(nnkLetSection).und(
          newNimNode(nnkIdentDefs).und(
            lenName,
            newNimNode(nnkEmpty),
            newCall("readInt16", streamID))))
        readBody.add(      ## result.name = @[]
          resName := ("@".prefix(newNimNode(nnkBracket))),
          newNimNode(nnkForStmt).und(  ## for item in 1..len:
            item,
            infix(1.lit, "..", lenName),
            newNimNode(nnkStmtList).und(
              newCall(  ## add(result.name, unpack[seqType](stream))
                "add", resName, newNimNode(nnkCall).und(readName, streamID)
        ) ) ) )
        packbody.add(
          newNimNode(nnkVarSection).und(newNimNode(nnkIdentDefs).und(
            lenName,  ## var lenName = int16(len(p.name))
            newIdentNode("int16"),
            newCall("int16", newCall("len", dotName)))),
          newCall("writeData", streamID, newNimNode(nnkAddr).und(lenName), 2.lit),
          newNimNode(nnkForStmt).und(  ## for item in 0..length - 1: pack(p.name[item], stream)
            item,
            infix(0.lit, "..", infix(lenName, "-", 1.lit)),
            newNimNode(nnkStmtList).und(
              newCall("echo", item, ": ".lit),
              newCall("pack", dotName[item], streamID))))
        #set the default value to @[] (new sequence)
        typeFields[i][2] = "@".prefix(newNimNode(nnkBracket))
      else:
        error("Unknown type: "& treeRepr(typeFields[i]))
    of nnkIdent: ##normal type
      case $typeFields[i][1].ident
      of "string": # length encoded string
        packBody.add(newCall("writeLEStr", streamID, dotName))
        readBody.add(resName := newCall("readLEStr", streamID))
      of "int8", "int16", "int32", "float32", "float64", "char", "bool":
        packBody.add(newCall(
          "writeData", streamID, newNimNode(nnkAddr).und(dotName), newCall("sizeof", dotName)))
        readBody.add(resName := newCall("read"& $typeFields[i][1].ident, streamID))
      else:  ## hopefully the type you specified was another defpacket() type
        packBody.add(newCall("pack", dotName, streamID))
        readBody.add(resName := newCall("read"& $typeFields[i][1].ident, streamID))
    else:
      error("I dont know what to do with: "& treerepr(typeFields[i]))

  var
    toStringFunc = newNimNode(nnkProcDef).und(
      newNimNode(nnkPostfix).und(
        ^"*",
        newNimNode(nnkAccQuoted).und(^"$")),
      emptyNode(),
      emptyNode(),
      newNimNode(nnkFormalParams).und(
        ^"string",
        newNimNode(nnkIdentDefs).und(
          packetID, # p: typeName
          typeName,
          emptyNode())),
      emptyNode(),
      emptyNode(),
      newNimNode(nnkStmtList).und(#[6]
        newNimNode(nnkAsgn).und(
          ^"result",                  ## result =
          newNimNode(nnkCall).und(#[6][0][1]
            ^"format",  ## format
            emptyNode()))))  ## "[TypeName   $1   $2]"
    formatStr = "["& $typeName.ident

  const emptyFields = {nnkEmpty, nnkNilLit}
  var objFields = newNimNode(nnkRecList)
  for i in 0.. < len(typeFields):
    let fname = typeFields[i][0]
    constructorParams.add(newNimNode(nnkIdentDefs).und(
      fname,
      typeFields[i][1],
      typeFields[i][2]))
    constructorBody.add((^"result").dot(fname) := fname)
    #export the name
    typeFields[i][0] = fname.postfix("*")
    if not(typeFields[i][2].kind in emptyFields):
      ## empty the type default for the type def
      typeFields[i][2] = newNimNode(nnkEmpty)
    objFields.add(typeFields[i])
    toStringFunc[6][0][1].add(
      prefix("$", packetID.dot(fname)))
    formatStr.add "   $"
    formatStr.add($(i + 1))

  formatStr.add ']'
  toStringFunc[6][0][1][1] = formatStr.lit()

  result.add(
    newNimNode(nnkTypeSection).und(
      newNimNode(nnkTypeDef).und(
        typeName.postfix("*"),
        newNimNode(nnkEmpty),
        newNimNode(nnkObjectTy).und(
          newNimNode(nnkEmpty), #not sure what this is
          newNimNode(nnkEmpty), #parent: OfInherit(Ident(!"SomeObj"))
          objFields))))
  result.add(constructor.und(constructorBody))
  result.add(pack.und(packBody))
  result.add(read.und(readBody))
  result.add(toStringFunc)
  when defined(GenPacketShowOutput):
    echo(repr(result))

proc `->`(a: string, b: string): NimNode {.compileTime.} =
  result = newNimNode(nnkIdentDefs).und(^a, ^b, newNimNode(nnkEmpty))
proc `->`(a: string, b: NimNode): NimNode {.compileTime.} =
  result = newNimNode(nnkIdentDefs).und(^a, b, newNimNode(nnkEmpty))
proc `->`(a, b: NimNode): NimNode {.compileTime.} =
  a[2] = b
  result = a

proc newProc*(name: string, params: varargs[NimNode], resultType: NimNode): NimNode {.compileTime.} =
  result = newNimNode(nnkProcDef).und(
    ^name,
    emptyNode(),
    emptyNode(),
    newNimNode(nnkFormalParams).und(resultType),
    emptyNode(),
    emptyNode(),
    newNimNode(nnkStmtList))
  result[3].add(params)
macro forwardPacket*(typeName: expr, underlyingType: typedesc): stmt {.immediate.} =
  result = newNimNode(nnkStmtList).und(
    newProc(
      "read"& $typeName.ident,
      ["s" -> "PStream" -> newNimNode(nnkNilLit)],
      typeName),
    newProc(
      "pack",
      [ "p" -> newNimNode(nnkVarTy).und(typeName),
        "s" -> "PStream" -> newNimNode(nnkNilLit)],
      emptyNode()))
  result[0][6].add(newNimNode(nnkDiscardStmt).und(
    newCall(
      "readData", ^"s", newNimNode(nnkAddr).und(^"result"), newCall("sizeof", ^"result")
    )))
  result[1][6].add(
    newCall(
      "writeData", ^"s", newNimNode(nnkAddr).und(^"p"), newCall(
        "sizeof", ^"p")))
  when defined(GenPacketShowOutput):
    echo(repr(result))

template forwardPacketT*(typeName: expr): stmt {.dirty, immediate.} =
  proc `read typeName`*(s: PStream): typeName =
    discard readData(s, addr result, sizeof(result))
  proc `pack typeName`*(p: var typeName; s: PStream) =
    writeData(s, addr p, sizeof(p))

when isMainModule:
  type
    SomeEnum = enum
      A = 0'i8,
      B, C
  forwardPacket(SomeEnum, int8)


  defPacket(Foo, tuple[x: array[0..4, int8]])
  var f = newFoo([4'i8, 3'i8, 2'i8, 1'i8, 0'i8])
  var s2 = newStringStream("")
  f.pack(s2)
  assert s2.data == "\4\3\2\1\0"

  var s = newStringStream()
  s.flushImpl = proc(s: PStream) =
    var z = PStringStream(s)
    z.setPosition(0)
    z.data.setLen(0)


  s.setPosition(0)
  s.data.setLen(0)
  var o = B
  o.pack(s)
  o = A
  o.pack(s)
  o = C
  o.pack(s)
  assert s.data == "\1\0\2"
  s.flush

  defPacket(Y, tuple[z: int8])
  proc `$`(z: Y): string = result = "Y("& $z.z &")"
  defPacket(TestPkt, tuple[x: seq[Y]])
  var test = newTestPkt()
  test.x.add([newY(5), newY(4), newY(3), newY(2), newY(1)])
  for itm in test.x:
    echo(itm)
  test.pack(s)
  echo(repr(s.data))
