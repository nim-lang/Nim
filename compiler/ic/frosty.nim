import std/macros
import std/streams

const
  frostyMagic* {.intdefine.} = 0xBADCAB ##
  ## A magic file value for our "format".
  frostyDebug* {.booldefine.} =
    when defined(nimcore): false
    elif defined(release): false
    else: true
  frostySorted* {.booldefine.} = false
  frostyNet* {.booldefine.} = when defined(nimcore): false else: true

# we'll only check hashes during debug builds
when frostyDebug:
  import std/strutils
  import std/hashes

when frostySorted:
  when frostyDebug:
    {.hint: "frosty using sorta".}
  import sorta

  type
    Serializer[T] = object
      stream: T
      stack: seq[pointer]
      ptrs: SortedTable[int, pointer]
      when not defined(release):
        indent: int

else:
  when frostyDebug:
    {.hint: "frosty using stdlib".}
  import std/tables

  type
    Serializer[T] = object
      stream: T
      stack: seq[pointer]
      ptrs: Table[int, pointer]
      when not defined(release):
        indent: int

type
  FreezeError* = ValueError  ##
  ## An error raised during `freeze`.
  ThawError* = ValueError    ##
  ## An error raised during `thaw`.

  Ice = object
    p: int
    when not defined(release):
      h: Hash

template refAddr(o: typed): int =
  when o is ref:
    if o.isNil: 0 else: cast[int](o)
  else:
    0

proc newSerializer[S](source: S): Serializer[S] {.raises: [].} =
  result = Serializer[S](stream: source)

proc write[S, T](s: var Serializer[S]; o: ref T; parent = 0)
proc read[S, T](s: var Serializer[S]; o: var ref T)
proc write[S, T](s: var Serializer[S]; o: T; parent = 0)
proc read[S, T](s: var Serializer[S]; o: var T)
proc write[S, T](s: var Serializer[S]; o: seq[T])
proc read[S, T](s: var Serializer[S]; o: var seq[T])
proc write(s: var Serializer[Stream]; o: string)
proc read(s: var Serializer[Stream]; o: var string)
proc readPrimitive[T](s: var Serializer[Stream]; o: var T)
proc writePrimitive[T](s: var Serializer[Stream]; o: T)

when frostyNet:
  import std/net

  proc write(s: var Serializer[Socket]; o: string)
  proc read(s: var Serializer[Socket]; o: var string)
  proc readPrimitive[T](s: var Serializer[Socket]; o: var T)

  # convenience to make certain calls more legible
  template socket(s: Serializer): Socket = s.stream

template greatenIndent(s: var Serializer; body: untyped): untyped =
  ## Used for debugging.
  when not defined(release):
    s.indent = s.indent + 2
    defer:
      s.indent = s.indent - 2
  body

template debung(s: Serializer; msg: string): untyped =
  ## Used for debugging.
  when not defined(release):
    when not defined(nimdoc):
      echo spaces(s.indent) & msg

when not defined(nimdoc):
  export greatenIndent, debung

template audit(o: typed; g: typed) =
  when defined(release):
    discard
  else:
    # if it's a pointer,
    if g.p != 0:
      # compute a hash
      let h =
        when compiles(hash(o)):
          hash(o)
        elif compiles(hash(o[])):
          hash(o[])
        else:
          hash(g.p)
      # if we read a hash,
      if g.h != 0:
        # check it,
        assert g.h == h
      else:
        # else, save it
        g.h = h

proc write(s: var Serializer[Stream]; o: string) =
  write(s.stream, len(o))   # put the str len
  write(s.stream, o)        # put the str data

proc read(s: var Serializer[Stream]; o: var string) =
  var l = len(o)                     # type inference
  read(s.stream, l)                  # get the str len
  setLen(o, l)                       # set the length
  if l > 0:
    if readData(s.stream, o.cstring, l) != l:
      raise newException(ThawError, "short read!")

proc write[S, T](s: var Serializer[S]; o: ref T; parent = 0) =
  # compute p and store it
  var g = Ice(p: refAddr(o))
  # if it's nonzero, also compute hash
  audit(o, g)

  # write the preamble
  s.write g
  if g.p != 0:
    if not hasKeyOrPut(s.ptrs, g.p, cast[pointer](o)):
      # we haven't written the value for this address yet,
      # so write it now
      if g.p != parent:
        s.write o[], parent = g.p
      else:
        raise newException(FreezeError, "unexpected cycle")

proc readTuple[S, T](s: var Serializer[S]; o: var T; skip = "") =
  var skipped = skip == ""
  for k, val in fieldPairs(o):
    if not skipped and k == skip:
      skipped = true
    else:
      # create a var that we can pass to the read()
      var x: typeof(val)
      s.read x
      val = x

proc writeTuple[S, T](s: var Serializer[S]; o: T; skip = ""; parent = 0) =
  var skipped = skip == ""
  s.greatenIndent:
    for k, val in fieldPairs(o):
      if not skipped and k == skip:
        skipped = true
      else:
        when val is ref:
          s.write val, parent = parent
        else:
          s.write val
        when defined(frostyDebug):
          let q = repr(val)
          s.debung k & ": " & $typeof(val) & " = " & q[low(q)..min(20, high(q))]

macro readObject[S, T](s: var Serializer[S]; o: var T) =
  # do nothing by default
  result = newEmptyNode()
  let
    readTuple = bindSym"readTuple"
    reader = bindSym("readPrimitive", rule = brClosed)
    typ = o.getTypeImpl
    sym = o.getTypeInst
  when defined(frostyDebug):
    echo typ.treeRepr
    echo typ.repr
  case typ.kind
  of nnkObjectTy:
    let variant = findChild(typ[^1], it.kind == nnkRecCase)
    if variant.isNil:
      # it's a simple named tuple/object
      result = newCall(readTuple, s, o)
    else:
      # it's an object variant; we need to unpack the discriminator first
      result = newStmtList()
      let disc = variant[0]        # the first IdentDefs under RecCase

      let name = disc[0]           # the symbol of the discriminator
      let dtyp = disc[1]           # the type of the discriminator

      when defined(frostyDebug):
        echo dtyp.getTypeImpl.treeRepr

      # create a variable into which we can read the discriminator
      let kind = genSym(nskVar, "kind")

      # declare our kind variable with its value type
      result.add nnkVarSection.newTree(newIdentDefs(kind, dtyp,
                                                    newEmptyNode()))

      # read the value of the discriminator into our `kind` variable
      result.add newCall(reader, s, kind)

      # create an object constructor for the variant object
      var ctor = nnkObjConstr.newNimNode

      # the first child is the name of the object type
      ctor.add ident(sym.strVal)

      # add `name: kind` to the variant object constructor
      ctor.add newColonExpr(name, kind)

      # assign it to the input symbol
      result.add newAssignment(o, ctor)

      # prepare a skip="field" argument to readTuple()
      let skipper = nnkExprEqExpr.newTree(ident"skip", newLit name.strVal)

      # read the remaining fields as determined by the discriminator
      result.add newCall(readTuple, s, o, skipper)

  of nnkTupleTy:
    # (name: "jeff", age: 34)
    result = newCall(readTuple, s, o)
  of nnkTupleConstr:
    # ("jeff", 34)
    result = newCall(readTuple, s, o)
  else:
    error "attempt to read unrecognized type: " & $typ.kind

macro writeObject[S, T](s: var Serializer[S]; o: T; parent = 0) =
  # do nothing by default
  result = newEmptyNode()
  let
    writeTuple = bindSym"writeTuple"
    writer = bindSym("writePrimitive", rule = brClosed)
    typ = o.getTypeImpl
  when defined(frostyDebug):
    echo typ.treeRepr
    echo typ.repr
  case typ.kind
  of nnkObjectTy:
    let variant = findChild(typ[^1], it.kind == nnkRecCase)
    if variant.isNil:
      # it's a simple named tuple/object
      result = newCall(writeTuple, s, o)
    else:
      # it's an object variant; we need to pack the discriminator first
      result = newStmtList()
      let disc = variant[0]        # the first IdentDefs under RecCase

      let name = disc[0]           # the symbol of the discriminator

      # write the value of the discriminator
      result.add newCall(writer, s, newDotExpr(o, name))

      # prepare a skip="field" argument to writeTuple()
      let skipper = nnkExprEqExpr.newTree(ident"skip", newLit name.strVal)
      # prepare a parent=parent argument to writeTuple()
      let parent = nnkExprEqExpr.newTree(ident"parent", parent)

      # write the remaining fields as determined by the discriminator
      result.add newCall(writeTuple, s, o, skipper, parent)

  of nnkTupleTy:
    # (name: "jeff", age: 34)
    result = newCall(writeTuple, s, o)
  of nnkTupleConstr:
    # ("jeff", 34)
    result = newCall(writeTuple, s, o)
  else:
    error "attempt to write unrecognized type: " & $typ.kind

proc read[S, T](s: var Serializer[S]; o: var ref T) =
  const
    unlikely = cast[pointer](-1)
  var
    g: Ice
  s.read g
  if g.p == 0:
    o = nil
  else:
    # a lookup is waaaay cheaper than an alloc
    let p = getOrDefault(s.ptrs, g.p, unlikely)
    if p == unlikely:
      o = new (ref T)
      s.ptrs[g.p] = cast[pointer](o)
      s.read o[]
      # after you read it, check the hash
      audit(o, g)
    else:
      o = cast[ref T](p)

proc write[S, T](s: var Serializer[S]; o: seq[T]) =
  runnableExamples:
    # start with some data
    var q = @[1, 1, 2, 3, 5]
    # prepare a string
    var s: string
    # write the data into the string
    s.freeze q
    # check that it matches our expectation
    assert len(s) == sizeof(frostyMagic) + sizeof(5) + 5*sizeof(0)
    # prepare a new seq to hold some data
    var l: seq[int]
    # populate the seq using the string as input
    s.thaw l
    # confirm that the two sequences of data match
    assert l == q

  s.write len(o)
  for item in items(o):
    s.write item

proc read[S, T](s: var Serializer[S]; o: var seq[T]) =
  var l = len(o)          # type inference
  s.read l                # get the len of the seq
  o.setLen(l)             # pre-alloc the sequence
  for item in mitems(o):  # iterate over mutable items
    s.read item           # read into the item

proc writePrimitive[T](s: var Serializer[Stream]; o: T) =
  write(s.stream, o)

proc write[S, T](s: var Serializer[S]; o: T; parent = 0) =
  when T is object or T is tuple:
    writeObject(s, o, parent = parent)
  else:
    writePrimitive(s, o)

proc readPrimitive[T](s: var Serializer[Stream]; o: var T) =
  streams.read(s.stream, o)

proc read[S, T](s: var Serializer[S]; o: var T) =
  when T is object or T is tuple:
    readObject(s, o)
  else:
    readPrimitive(s, o)

proc freeze*[T](o: T; stream: Stream) =
  ## Write `o` into `stream`.
  ##
  ## A "magic" value will be written, first.
  var s = newSerializer(stream)
  s.write frostyMagic
  s.write o

proc freeze*[T](o: T; str: var string) =
  ## Write `o` into `str`.
  ##
  ## A "magic" value will prefix the result.
  runnableExamples:
    import uri
    # start with some data
    var q = parseUri"https://github.org/nim-lang/Nim"
    # prepare a string
    var s: string
    # write the data into the string
    freeze(q, s)
    # prepare a new url object
    var url: Uri
    # populate the url using the string as input
    thaw(s, url)
    # confirm that two objects match
    assert url == q

  var ss = newStringStream(str)
  freeze(o, ss)
  setPosition(ss, 0)
  str = readAll(ss)
  close ss

proc freeze*[T](o: T): string =
  ## Turn `o` into a string.
  ##
  ## A "magic" value will prefix the result.
  runnableExamples:
    import uri
    # start with some data
    var q = parseUri"https://github.org/nim-lang/Nim"
    # freeze `q` into `s`
    var s = freeze(q)
    # thaw `s` into `u`
    var u = thaw[Uri](s)
    # confirm that two objects match
    assert u == q

  freeze(o, result)

proc thaw*[T](stream: Stream; o: var T) =
  ## Read `o` from `stream`.
  ##
  ## First, a "magic" value will be read.  A `ThawError`
  ## will be raised if the magic value is not as expected.
  var version: int
  stream.read version
  if version != frostyMagic:
    raise newException(ThawError, "expected magic " & $frostyMagic)
  else:
    var s = newSerializer(stream)
    s.read o

proc thaw*[T](str: string; o: var T) =
  ## Read `o` from `str`.
  ##
  ## A "magic" value must prefix the input string.
  var ss = newStringStream(str)
  thaw(ss, o)
  close ss

proc thaw*[T](str: string): T =
  ## Read value of `T` from `str`.
  ##
  ## A "magic" value must prefix the input string.
  thaw(str, result)

when frostyNet:
  proc write(s: var Serializer[Socket]; o: string) =
    var l = len(o)            # type inference
    # send the length of the string
    if send(s.socket, data = addr l, size = sizeof(l)) != sizeof(l):
      raise newException(FreezeError, "short write; socket closed?")
    # send the string itself; this can raise...
    send(s.socket, data = o)

  proc read(s: var Serializer[Socket]; o: var string) =
    var l = len(o)            # type inference
    # receive the string size
    if recv(s.socket, data = addr l, size = sizeof(l)) != sizeof(l):
      raise newException(ThawError, "short read; socket closed?")
    # for the following recv(), "data must be initialized"
    setLen(o, l)
    if l > 0:
      # receive the string
      if recv(s.socket, data = o, size = l) != l:
        raise newException(ThawError, "short read; socket closed?")

  proc writePrimitive[T](s: var Serializer[Socket]; o: T) =
    if send(s.socket, data = addr o, size = sizeof(o)) != sizeof(o):
      raise newException(FreezeError, "short write; socket closed?")

  proc readPrimitive[T](s: var Serializer[Socket]; o: var T) =
    if net.recv(s.socket, data = addr o, size = sizeof(o)) != sizeof(o):
      raise newException(ThawError, "short read; socket closed?")

  proc freeze*[T](o: T; socket: Socket) =
    ## Send `o` via `socket`.
    ##
    ## A "magic" value will be written, first.
    var s = newSerializer(socket)
    s.write frostyMagic
    s.write o

  proc thaw*[T](socket: Socket; o: var T) =
    ## Receive `o` from `socket`.
    ##
    ## First, a "magic" value will be read.  A `ThawError`
    ## will be raised if the magic value is not as expected.
    var v: int
    if recv(socket, data = addr v, size = sizeof(v)) != sizeof(v):
      raise newException(ThawError, "short read; socket closed?")
    if v != frostyMagic:
      raise newException(ThawError, "expected magic " & $frostyMagic)
    else:
      var s = newSerializer(socket)
      s.read o

