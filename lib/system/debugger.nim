#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This file implements basic features for any debugger.

type
  TVarSlot* {.compilerproc, final.} = object ## a slot in a frame
    address*: pointer ## the variable's address
    typ*: PNimType    ## the variable's type
    name*: cstring    ## the variable's name; for globals this is "module.name"

  PExtendedFrame = ptr TExtendedFrame
  TExtendedFrame = object  # If the debugger is enabled the compiler
                           # provides an extended frame. Of course
                           # only slots that are
                           # needed are allocated and not 10_000,
                           # except for the global data description.
    f: TFrame
    slots: array[0..10_000, TVarSlot]

var
  dbgGlobalData: TExtendedFrame # this reserves much space, but
                                # for now it is the most practical way

proc dbgRegisterGlobal(name: cstring, address: pointer,
                       typ: PNimType) {.compilerproc.} =
  let i = dbgGlobalData.f.len
  if i >= high(dbgGlobalData.slots):
    #debugOut("[Warning] cannot register global ")
    return
  dbgGlobalData.slots[i].name = name
  dbgGlobalData.slots[i].typ = typ
  dbgGlobalData.slots[i].address = address
  inc(dbgGlobalData.f.len)

proc getLocal*(frame: PFrame; slot: int): TVarSlot {.inline.} =
  ## retrieves the meta data for the local variable at `slot`. CAUTION: An
  ## invalid `slot` value causes a corruption!
  result = cast[PExtendedFrame](frame).slots[slot]

proc getGlobalLen*(): int {.inline.} =
  ## gets the number of registered globals.
  result = dbgGlobalData.f.len

proc getGlobal*(slot: int): TVarSlot {.inline.} =
  ## retrieves the meta data for the global variable at `slot`. CAUTION: An
  ## invalid `slot` value causes a corruption!
  result = dbgGlobalData.slots[slot]

# ------------------- breakpoint support ------------------------------------

type
  TBreakpoint* = object  ## represents a break point
    low*, high*: int     ## range from low to high; if disabled
                         ## both low and high are set to their negative values
    filename*: cstring   ## the filename of the breakpoint

var
  dbgBP: array[0..127, TBreakpoint] # breakpoints
  dbgBPlen: int
  dbgBPbloom: int64  # we use a bloom filter to speed up breakpoint checking
  
  dbgFilenames*: array[0..300, cstring] ## registered filenames;
                                        ## 'nil' terminated
  dbgFilenameLen: int

proc dbgRegisterFilename(filename: cstring) {.compilerproc.} =
  # XXX we could check for duplicates here for DLL support
  dbgFilenames[dbgFilenameLen] = filename
  inc dbgFilenameLen

proc dbgRegisterBreakpoint(line: int,
                           filename, name: cstring) {.compilerproc.} =
  let x = dbgBPlen
  if x >= high(dbgBP):
    #debugOut("[Warning] cannot register breakpoint")
    return
  inc(dbgBPlen)
  dbgBP[x].filename = filename
  dbgBP[x].low = line
  dbgBP[x].high = line
  dbgBPbloom = dbgBPbloom or line

proc addBreakpoint*(filename: cstring, lo, hi: int): bool =
  let x = dbgBPlen
  if x >= high(dbgBP): return false
  inc(dbgBPlen)
  result = true
  dbgBP[x].filename = filename
  dbgBP[x].low = lo
  dbgBP[x].high = hi
  for line in lo..hi: dbgBPbloom = dbgBPbloom or line

const
  FileSystemCaseInsensitive = defined(windows) or defined(dos) or defined(os2)

proc fileMatches(c, bp: cstring): bool =
  # bp = breakpoint filename
  # c = current filename
  # we consider it a match if bp is a suffix of c
  # and the character for the suffix does not exist or
  # is one of: \  /  :
  # depending on the OS case does not matter!
  var blen: int = c_strlen(bp)
  var clen: int = c_strlen(c)
  if blen > clen: return false
  # check for \ /  :
  if clen-blen-1 >= 0 and c[clen-blen-1] notin {'\\', '/', ':'}:
    return false
  var i = 0
  while i < blen:
    var x = bp[i]
    var y = c[i+clen-blen]
    when FileSystemCaseInsensitive:
      if x >= 'A' and x <= 'Z': x = chr(ord(x) - ord('A') + ord('a'))
      if y >= 'A' and y <= 'Z': y = chr(ord(y) - ord('A') + ord('a'))
    if x != y: return false
    inc(i)
  return true

proc canonFilename*(filename: cstring): cstring =
  ## returns 'nil' if the filename cannot be found.
  for i in 0 .. <dbgFilenameLen:
    result = dbgFilenames[i]
    if fileMatches(result, filename): return result
  result = nil

iterator listBreakpoints*(): ptr TBreakpoint =
  ## lists all breakpoints.
  for i in 0..dbgBPlen-1: yield addr(dbgBP[i])

proc isActive*(b: ptr TBreakpoint): bool = b.low > 0
proc flip*(b: ptr TBreakpoint) =
  ## enables or disables 'b' depending on its current state.
  b.low = -b.low; b.high = -b.high

proc checkBreakpoints*(filename: cstring, line: int): ptr TBreakpoint =
  ## in which breakpoint (if any) we are.
  if (dbgBPbloom and line) != line: return nil
  for b in listBreakpoints():
    if line >= b.low and line <= b.high and filename == b.filename: return b

# ------------------- watchpoint support ------------------------------------

type
  THash = int
  TWatchpoint {.pure, final.} = object
    name: cstring
    address: pointer
    typ: PNimType
    oldValue: THash

var
  Watchpoints: array [0..99, TWatchpoint]
  WatchpointsLen: int

proc `!&`(h: THash, val: int): THash {.inline.} =
  result = h +% val
  result = result +% result shl 10
  result = result xor (result shr 6)

proc `!$`(h: THash): THash {.inline.} =
  result = h +% h shl 3
  result = result xor (result shr 11)
  result = result +% result shl 15

proc hash(data: pointer, size: int): THash =
  var h: THash = 0
  var p = cast[cstring](data)
  var i = 0
  var s = size
  while s > 0:
    h = h !& ord(p[i])
    inc(i)
    dec(s)
  result = !$h

proc hashGcHeader(data: pointer): THash =
  const headerSize = sizeof(int)*2
  result = hash(cast[pointer](cast[int](data) -% headerSize), headerSize)

proc genericHashAux(dest: pointer, mt: PNimType, shallow: bool,
                    h: THash): THash
proc genericHashAux(dest: pointer, n: ptr TNimNode, shallow: bool,
                    h: THash): THash =
  var d = cast[TAddress](dest)
  case n.kind
  of nkSlot:
    result = genericHashAux(cast[pointer](d +% n.offset), n.typ, shallow, h)
  of nkList:
    result = h
    for i in 0..n.len-1: 
      result = result !& genericHashAux(dest, n.sons[i], shallow, result)
  of nkCase:
    result = h !& hash(cast[pointer](d +% n.offset), n.typ.size)
    var m = selectBranch(dest, n)
    if m != nil: result = genericHashAux(dest, m, shallow, result)
  of nkNone: sysAssert(false, "genericHashAux")

proc genericHashAux(dest: pointer, mt: PNimType, shallow: bool, 
                    h: THash): THash =
  sysAssert(mt != nil, "genericHashAux 2")
  case mt.Kind
  of tyString:
    var x = cast[ppointer](dest)[]
    result = h
    if x != nil:
      let s = cast[NimString](x)
      when defined(trackGcHeaders):
        result = result !& hashGcHeader(x)
      else:
        result = result !& hash(x, s.len)
  of tySequence:
    var x = cast[ppointer](dest)
    var dst = cast[taddress](cast[ppointer](dest)[])
    result = h
    if dst != 0:
      when defined(trackGcHeaders):
        result = result !& hashGcHeader(cast[ppointer](dest)[])
      else:
        for i in 0..cast[pgenericseq](dst).len-1:
          result = result !& genericHashAux(
            cast[pointer](dst +% i*% mt.base.size +% GenericSeqSize),
            mt.Base, shallow, result)
  of tyObject, tyTuple:
    # we don't need to copy m_type field for tyObject, as they are equal anyway
    result = genericHashAux(dest, mt.node, shallow, h)
  of tyArray, tyArrayConstr:
    let d = cast[TAddress](dest)
    result = h
    for i in 0..(mt.size div mt.base.size)-1:
      result = result !& genericHashAux(cast[pointer](d +% i*% mt.base.size),
                                        mt.base, shallow, result)
  of tyRef:
    when defined(trackGcHeaders):
      var s = cast[ppointer](dest)[]
      if s != nil:
        result = result !& hashGcHeader(s)
    else:
      if shallow:
        result = h !& hash(dest, mt.size)
      else:
        result = h
        var s = cast[ppointer](dest)[]
        if s != nil:
          result = result !& genericHashAux(s, mt.base, shallow, result)
  else:
    result = h !& hash(dest, mt.size) # hash raw bits

proc genericHash(dest: pointer, mt: PNimType): int =
  result = genericHashAux(dest, mt, false, 0)
  
proc dbgRegisterWatchpoint(address: pointer, name: cstring,
                           typ: PNimType) {.compilerproc.} =
  let L = WatchpointsLen
  for i in 0.. <L:
    if Watchpoints[i].name == name:
      # address may have changed:
      Watchpoints[i].address = address
      return
  if L >= watchPoints.high:
    #debugOut("[Warning] cannot register watchpoint")
    return
  Watchpoints[L].name = name
  Watchpoints[L].address = address
  Watchpoints[L].typ = typ
  Watchpoints[L].oldValue = genericHash(address, typ)
  inc WatchpointsLen

proc dbgUnregisterWatchpoints*() =
  WatchpointsLen = 0

var
  dbgLineHook*: proc () {.nimcall.}
    ## set this variable to provide a procedure that should be called before
    ## each executed instruction. This should only be used by debuggers!
    ## Only code compiled with the ``debugger:on`` switch calls this hook.

  dbgWatchpointHook*: proc (watchpointName: cstring) {.nimcall.}
  
proc checkWatchpoints =
  let L = WatchpointsLen
  for i in 0.. <L:
    let newHash = genericHash(Watchpoints[i].address, Watchpoints[i].typ)
    if newHash != Watchpoints[i].oldValue:
      dbgWatchpointHook(Watchpoints[i].name)
      Watchpoints[i].oldValue = newHash

proc endb(line: int, file: cstring) {.compilerproc, noinline.} =
  # This proc is called before every Nim code line!
  if framePtr == nil: return
  if dbgWatchpointHook != nil: checkWatchpoints()
  framePtr.line = line # this is done here for smaller code size!
  framePtr.filename = file
  if dbgLineHook != nil: dbgLineHook()

include "system/endb"
