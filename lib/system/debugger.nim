#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the embedded debugger that can be linked
# with the application. Mostly we do not use dynamic memory here as that
# would interfere with the GC and trigger ON/OFF errors if the
# user program corrupts memory. Unfortunately, for dispaying
# variables we use the ``system.repr()`` proc which uses Nimrod
# strings and thus allocates memory from the heap. Pity, but
# I do not want to implement ``repr()`` twice.

type
  TStaticStr {.pure, final.} = object
    len: int
    data: array[0..100, char]

  TDbgState = enum
    dbOff,        # debugger is turned off
    dbStepInto,   # debugger is in tracing mode
    dbStepOver,
    dbSkipCurrent,
    dbQuiting,    # debugger wants to quit
    dbBreakpoints # debugger is only interested in breakpoints

  TDbgBreakpoint {.final.} = object
    low, high: int   # range from low to high; if disabled
                     # both low and high are set to their negative values
                     # this makes the check faster and safes memory
    filename: cstring
    name: TStaticStr     # name of breakpoint

  TVarSlot {.compilerproc, final.} = object # variable slots used for debugger:
    address: pointer
    typ: PNimType
    name: cstring   # for globals this is "module.name"

  PExtendedFrame = ptr TExtendedFrame
  TExtendedFrame {.final.} = object  # If the debugger is enabled the compiler
                                     # provides an extended frame. Of course
                                     # only slots that are
                                     # needed are allocated and not 10_000,
                                     # except for the global data description.
    f: TFrame
    slots: array[0..10_000, TVarSlot]

var
  dbgUser: TStaticStr   # buffer for user input; first command is ``step_into``
                        # needs to be global cause we store the last command
                        # in it
  dbgState: TDbgState   # state of debugger
  dbgBP: array[0..127, TDbgBreakpoint] # breakpoints
  dbgBPlen: int

  dbgSkipToFrame: PFrame # frame to be skipped to

  dbgGlobalData: TExtendedFrame # this reserves much space, but
                                # for now it is the most practical way

  maxDisplayRecDepth: int = 5 # do not display too much data!

proc setLen(s: var TStaticStr, newLen=0) =
  s.len = newLen
  s.data[newLen] = '\0'

proc add(s: var TStaticStr, c: char) =
  if s.len < high(s.data)-1:
    s.data[s.len] = c
    s.data[s.len+1] = '\0'
    inc s.len

proc add(s: var TStaticStr, c: cstring) =
  var i = 0
  while c[i] != '\0':
    add s, c[i]
    inc i

proc assign(s: var TStaticStr, c: cstring) =
  setLen(s)
  add s, c

proc `==`(a, b: TStaticStr): bool =
  if a.len == b.len:
    for i in 0 .. a.len-1:
      if a.data[i] != b.data[i]: return false
    return true

proc `==`(a: TStaticStr, b: cstring): bool =
  result = c_strcmp(a.data, b) == 0

proc findBreakpoint(name: TStaticStr): int =
  # returns -1 if not found
  for i in countdown(dbgBPlen-1, 0):
    if name == dbgBP[i].name: return i
  return -1

proc write(f: TFile, s: TStaticStr) =
  write(f, cstring(s.data))

proc ListBreakPoints() =
  write(stdout, "*** endb| Breakpoints:\n")
  for i in 0 .. dbgBPlen-1:
    write(stdout, dbgBP[i].name)
    write(stdout, ": ")
    write(stdout, abs(dbgBP[i].low))
    write(stdout, "..")
    write(stdout, abs(dbgBP[i].high))
    write(stdout, dbgBP[i].filename)
    if dbgBP[i].low < 0:
      write(stdout, " [disabled]\n")
    else:
      write(stdout, "\n")
  write(stdout, "***\n")

proc openAppend(filename: cstring): TFile =
  var p: pointer = fopen(filename, "ab")
  if p != nil:
    result = cast[TFile](p)
    write(result, "----------------------------------------\n")

proc dbgRepr(p: pointer, typ: PNimType): string =
  var cl: TReprClosure
  initReprClosure(cl)
  cl.recDepth = maxDisplayRecDepth
  # locks for the GC turned out to be a bad idea...
  # inc(recGcLock)
  result = ""
  reprAux(result, p, typ, cl)
  # dec(recGcLock)
  deinitReprClosure(cl)

proc writeVariable(stream: TFile, slot: TVarSlot) =
  write(stream, slot.name)
  write(stream, " = ")
  writeln(stream, dbgRepr(slot.address, slot.typ))

proc ListFrame(stream: TFile, f: PExtendedFrame) =
  write(stream, "*** endb| Frame (")
  write(stream, f.f.len)
  write(stream, " slots):\n")
  for i in 0 .. f.f.len-1:
    writeVariable(stream, f.slots[i])
  write(stream, "***\n")

proc ListVariables(stream: TFile, f: PExtendedFrame) =
  write(stream, "*** endb| Frame (")
  write(stream, f.f.len)
  write(stream, " slots):\n")
  for i in 0 .. f.f.len-1:
    writeln(stream, f.slots[i].name)
  write(stream, "***\n")

proc debugOut(msg: cstring) =
  # the *** *** markers are for easy recognition of debugger
  # output for external frontends.
  write(stdout, "*** endb| ")
  write(stdout, msg)
  write(stdout, "***\n")

proc dbgFatal(msg: cstring) =
  debugOut(msg)
  dbgAborting = True # the debugger wants to abort
  quit(1)

proc findVariable(frame: PExtendedFrame, varname: cstring): int =
  for i in 0 .. frame.f.len - 1:
    if c_strcmp(frame.slots[i].name, varname) == 0: return i
  return -1

proc dbgShowCurrentProc(dbgFramePointer: PFrame) =
  if dbgFramePointer != nil:
    write(stdout, "*** endb| now in proc: ")
    write(stdout, dbgFramePointer.procname)
    write(stdout, " ***\n")
  else:
    write(stdout, "*** endb| (proc name not available) ***\n")

proc dbgShowExecutionPoint() =
  write(stdout, "*** endb| ")
  write(stdout, framePtr.filename)
  write(stdout, "(")
  write(stdout, framePtr.line)
  write(stdout, ") ")
  write(stdout, framePtr.procname)
  write(stdout, " ***\n")

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
    var x, y: char
    x = bp[i]
    y = c[i+clen-blen]
    when FileSystemCaseInsensitive:
      if x >= 'A' and x <= 'Z': x = chr(ord(x) - ord('A') + ord('a'))
      if y >= 'A' and y <= 'Z': y = chr(ord(y) - ord('A') + ord('a'))
    if x != y: return false
    inc(i)
  return true

proc dbgBreakpointReached(line: int): int =
  for i in 0..dbgBPlen-1:
    if line >= dbgBP[i].low and line <= dbgBP[i].high and
        fileMatches(framePtr.filename, dbgBP[i].filename): return i
  return -1

proc scanAndAppendWord(src: cstring, a: var TStaticStr, start: int): int =
  result = start
  # skip whitespace:
  while src[result] in {'\t', ' '}: inc(result)
  while True:
    case src[result]
    of 'a'..'z', '0'..'9': add(a, src[result])
    of '_': nil # just skip it
    of 'A'..'Z': add(a, chr(ord(src[result]) - ord('A') + ord('a')))
    else: break
    inc(result)

proc scanWord(src: cstring, a: var TStaticStr, start: int): int =
  setlen(a)
  result = scanAndAppendWord(src, a, start)

proc scanFilename(src: cstring, a: var TStaticStr, start: int): int =
  result = start
  setLen a
  # skip whitespace:
  while src[result] in {'\t', ' '}: inc(result)
  while src[result] notin {'\t', ' ', '\0'}:
    add(a, src[result])
    inc(result)

proc scanNumber(src: cstring, a: var int, start: int): int =
  result = start
  a = 0
  while src[result] in {'\t', ' '}: inc(result)
  while true:
    case src[result]
    of '0'..'9': a = a * 10 + ord(src[result]) - ord('0')
    of '_': nil # skip underscores (nice for long line numbers)
    else: break
    inc(result)

proc dbgHelp() =
  debugOut("""
list of commands (see the manual for further help):
              GENERAL
h, help                 display this help message
q, quit                 quit the debugger and the program
<ENTER>                 repeat the previous debugger command
              EXECUTING
s, step                 single step, stepping into routine calls
n, next                 single step, without stepping into routine calls
f, skipcurrent          continue execution until the current routine finishes
c, continue, r, run     continue execution until the next breakpoint
i, ignore               continue execution, ignore all breakpoints
              BREAKPOINTS
b, break <name> [fromline [toline]] [file]
                        set a new breakpoint named 'name' for line and file
                        if line or file are omitted the current one is used
breakpoints             display the entire breakpoint list
disable <name>          disable a breakpoint
enable  <name>          enable a breakpoint
              DATA DISPLAY
e, eval <expr>          evaluate the expression <expr>
o, out <file> <expr>    evaluate <expr> and write it to <file>
w, where                display the current execution point
stackframe [file]       display current stack frame [and write it to file]
u, up                   go up in the call stack
d, down                 go down in the call stack
bt, backtrace           display the entire call stack
l, locals               display available local variables
g, globals              display available global variables
maxdisplay <integer>    set the display's recursion maximum
""")

proc InvalidCommand() =
  debugOut("[Warning] invalid command ignored (type 'h' for help) ")

proc hasExt(s: cstring): bool =
  # returns true if s has a filename extension
  var i = 0
  while s[i] != '\0':
    if s[i] == '.': return true
    inc i

proc setBreakPoint(s: cstring, start: int) =
  var dbgTemp: TStaticStr
  var i = scanWord(s, dbgTemp, start)
  if i <= start:
    InvalidCommand()
    return
  if dbgBPlen >= high(dbgBP):
    debugOut("[Warning] no breakpoint could be set; out of breakpoint space ")
    return
  var x = dbgBPlen
  inc(dbgBPlen)
  dbgBP[x].name = dbgTemp
  i = scanNumber(s, dbgBP[x].low, i)
  if dbgBP[x].low == 0:
    # set to current line:
    dbgBP[x].low = framePtr.line
  i = scanNumber(s, dbgBP[x].high, i)
  if dbgBP[x].high == 0: # set to low:
    dbgBP[x].high = dbgBP[x].low
  i = scanFilename(s, dbgTemp, i)
  if dbgTemp.len != 0:
    debugOut("[Warning] explicit filename for breakpoint not supported")
    when false:
      if not hasExt(dbgTemp.data): add(dbgTemp, ".nim")
      dbgBP[x].filename = dbgTemp
    dbgBP[x].filename = framePtr.filename
  else: # use current filename
    dbgBP[x].filename = framePtr.filename
  # skip whitespace:
  while s[i] in {' ', '\t'}: inc(i)
  if s[i] != '\0':
    dec(dbgBPLen) # remove buggy breakpoint
    InvalidCommand()

proc BreakpointSetEnabled(s: cstring, start, enabled: int) =
  var dbgTemp: TStaticStr
  var i = scanWord(s, dbgTemp, start)
  if i <= start:
    InvalidCommand()
    return
  var x = findBreakpoint(dbgTemp)
  if x < 0: debugOut("[Warning] breakpoint does not exist ")
  elif enabled * dbgBP[x].low < 0: # signs are different?
    dbgBP[x].low = -dbgBP[x].low
    dbgBP[x].high = -dbgBP[x].high

proc dbgEvaluate(stream: TFile, s: cstring, start: int,
                 currFrame: PExtendedFrame) =
  var dbgTemp: tstaticstr
  var i = scanWord(s, dbgTemp, start)
  while s[i] in {' ', '\t'}: inc(i)
  var f = currFrame
  if s[i] == '.':
    inc(i) # skip '.'
    add(dbgTemp, '.')
    i = scanAndAppendWord(s, dbgTemp, i)
    # search for global var:
    f = addr(dbgGlobalData)
  if s[i] != '\0':
    debugOut("[Warning] could not parse expr ")
    return
  var j = findVariable(f, dbgTemp.data)
  if j < 0:
    debugOut("[Warning] could not find variable ")
    return
  writeVariable(stream, f.slots[j])

proc dbgOut(s: cstring, start: int, currFrame: PExtendedFrame) =
  var dbgTemp: tstaticstr
  var i = scanFilename(s, dbgTemp, start)
  if dbgTemp.len == 0:
    InvalidCommand()
    return
  var stream = openAppend(dbgTemp.data)
  if stream == nil:
    debugOut("[Warning] could not open or create file ")
    return
  dbgEvaluate(stream, s, i, currFrame)
  close(stream)

proc dbgStackFrame(s: cstring, start: int, currFrame: PExtendedFrame) =
  var dbgTemp: TStaticStr
  var i = scanFilename(s, dbgTemp, start)
  if dbgTemp.len == 0:
    # just write it to stdout:
    ListFrame(stdout, currFrame)
  else:
    var stream = openAppend(dbgTemp.data)
    if stream == nil:
      debugOut("[Warning] could not open or create file ")
      return
    ListFrame(stream, currFrame)
    close(stream)

proc readLine(f: TFile, line: var TStaticStr): bool =
  while True:
    var c = fgetc(f)
    if c < 0'i32:
      if line.len > 0: break
      else: return false
    if c == 10'i32: break # LF
    if c == 13'i32:  # CR
      c = fgetc(f) # is the next char LF?
      if c != 10'i32: ungetc(c, f) # no, put the character back
      break
    add line, chr(int(c))
  result = true

proc dbgWriteStackTrace(f: PFrame)
proc CommandPrompt() =
  # if we return from this routine, user code executes again
  var
    again = True
    dbgFramePtr = framePtr # for going down and up the stack
    dbgDown = 0 # how often we did go down
    dbgTemp: TStaticStr

  while again:
    write(stdout, "*** endb| >>")
    let oldLen = dbgUser.len
    dbgUser.len = 0
    if not readLine(stdin, dbgUser): break
    if dbgUser.len == 0: dbgUser.len = oldLen
    # now look what we have to do:
    var i = scanWord(dbgUser.data, dbgTemp, 0)
    template `?`(x: expr): expr = dbgTemp == cstring(x)
    if ?"s" or ?"step":
      dbgState = dbStepInto
      again = false
    elif ?"n" or ?"next":
      dbgState = dbStepOver
      dbgSkipToFrame = framePtr
      again = false
    elif ?"f" or ?"skipcurrent":
      dbgState = dbSkipCurrent
      dbgSkipToFrame = framePtr.prev
      again = false
    elif ?"c" or ?"continue" or ?"r" or ?"run":
      dbgState = dbBreakpoints
      again = false
    elif ?"i" or ?"ignore":
      dbgState = dbOff
      again = false
    elif ?"h" or ?"help":
      dbgHelp()
    elif ?"q" or ?"quit":
      dbgState = dbQuiting
      dbgAborting = True
      again = false
      quit(1) # BUGFIX: quit with error code > 0
    elif ?"e" or ?"eval":
      dbgEvaluate(stdout, dbgUser.data, i, cast[PExtendedFrame](dbgFramePtr))
    elif ?"o" or ?"out":
      dbgOut(dbgUser.data, i, cast[PExtendedFrame](dbgFramePtr))
    elif ?"stackframe":
      dbgStackFrame(dbgUser.data, i, cast[PExtendedFrame](dbgFramePtr))
    elif ?"w" or ?"where":
      dbgShowExecutionPoint()
    elif ?"l" or ?"locals":
      ListVariables(stdout, cast[PExtendedFrame](dbgFramePtr))
    elif ?"g" or ?"globals":
      ListVariables(stdout, addr(dbgGlobalData))
    elif ?"u" or ?"up":
      if dbgDown <= 0:
        debugOut("[Warning] cannot go up any further ")
      else:
        dbgFramePtr = framePtr
        for j in 0 .. dbgDown-2: # BUGFIX
          dbgFramePtr = dbgFramePtr.prev
        dec(dbgDown)
      dbgShowCurrentProc(dbgFramePtr)
    elif ?"d" or ?"down":
      if dbgFramePtr != nil:
        inc(dbgDown)
        dbgFramePtr = dbgFramePtr.prev
        dbgShowCurrentProc(dbgFramePtr)
      else:
        debugOut("[Warning] cannot go down any further ")
    elif ?"bt" or ?"backtrace":
      dbgWriteStackTrace(framePtr)
    elif ?"b" or ?"break":
      setBreakPoint(dbgUser.data, i)
    elif ?"breakpoints":
      ListBreakPoints()
    elif ?"disable":
      BreakpointSetEnabled(dbgUser.data, i, -1)
    elif ?"enable":
      BreakpointSetEnabled(dbgUser.data, i, +1)
    elif ?"maxdisplay":
      var parsed: int
      i = scanNumber(dbgUser.data, parsed, i)
      if dbgUser.data[i-1] in {'0'..'9'}:
        if parsed == 0: maxDisplayRecDepth = -1
        else: maxDisplayRecDepth = parsed
      else:
        InvalidCommand()
    else: InvalidCommand()

proc endbStep() =
  # we get into here if an unhandled exception has been raised
  # XXX: do not allow the user to run the program any further?
  # XXX: BUG: the frame is lost here!
  dbgShowExecutionPoint()
  CommandPrompt()

proc checkForBreakpoint() =
  let i = dbgBreakpointReached(framePtr.line)
  if i >= 0:
    write(stdout, "*** endb| reached ")
    write(stdout, dbgBP[i].name)
    write(stdout, " in ")
    write(stdout, framePtr.filename)
    write(stdout, "(")
    write(stdout, framePtr.line)
    write(stdout, ") ")
    write(stdout, framePtr.procname)
    write(stdout, " ***\n")
    CommandPrompt()

# interface to the user program:

proc dbgRegisterBreakpoint(line: int,
                           filename, name: cstring) {.compilerproc.} =
  let x = dbgBPlen
  if x >= high(dbgBP):
    debugOut("[Warning] cannot register breakpoint")
    return
  inc(dbgBPlen)
  dbgBP[x].name.assign(name)
  dbgBP[x].filename = filename
  dbgBP[x].low = line
  dbgBP[x].high = line

proc dbgRegisterGlobal(name: cstring, address: pointer,
                       typ: PNimType) {.compilerproc.} =
  let i = dbgGlobalData.f.len
  if i >= high(dbgGlobalData.slots):
    debugOut("[Warning] cannot register global ")
    return
  dbgGlobalData.slots[i].name = name
  dbgGlobalData.slots[i].typ = typ
  dbgGlobalData.slots[i].address = address
  inc(dbgGlobalData.f.len)

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

proc hash(Data: Pointer, Size: int): THash =
  var h: THash = 0
  var p = cast[cstring](Data)
  var i = 0
  var s = size
  while s > 0:
    h = h !& ord(p[i])
    Inc(i)
    Dec(s)
  result = !$h

proc genericHashAux(dest: Pointer, mt: PNimType, shallow: bool,
                    h: THash): THash
proc genericHashAux(dest: Pointer, n: ptr TNimNode, shallow: bool,
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

proc genericHashAux(dest: Pointer, mt: PNimType, shallow: bool, 
                    h: THash): THash =
  sysAssert(mt != nil, "genericHashAux 2")
  case mt.Kind
  of tyString:
    var x = cast[ppointer](dest)[]
    result = h
    if x != nil:
      let s = cast[NimString](x)
      when true:
        result = result !& hash(x, s.len)
      else:
        let y = cast[pointer](cast[int](x) -% 2*sizeof(int))
        result = result !& hash(y, s.len + 2*sizeof(int))
  of tySequence:
    var x = cast[ppointer](dest)
    var dst = cast[taddress](cast[ppointer](dest)[])
    result = h
    if dst != 0:
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
    if shallow:
      result = h !& hash(dest, mt.size)
    else:
      result = h
      var s = cast[ppointer](dest)[]
      if s != nil:
        result = result !& genericHashAux(s, mt.base, shallow, result)
        # hash the object header:
        #const headerSize = sizeof(int)*2
        #result = result !& hash(cast[pointer](cast[int](s) -% headerSize),
        #                        headerSize)
  else:
    result = h !& hash(dest, mt.size) # hash raw bits

proc genericHash(dest: Pointer, mt: PNimType): int =
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
    debugOut("[Warning] cannot register watchpoint")
    return
  Watchpoints[L].name = name
  Watchpoints[L].address = address
  Watchpoints[L].typ = typ
  Watchpoints[L].oldValue = genericHash(address, typ)
  inc WatchpointsLen

proc dbgWriteStackTrace(f: PFrame) =
  const
    firstCalls = 32
  var
    it = f
    i = 0
    total = 0
    tempFrames: array [0..127, PFrame]
  while it != nil and i <= high(tempFrames)-(firstCalls-1):
    # the (-1) is for a nil entry that marks where the '...' should occur
    tempFrames[i] = it
    inc(i)
    inc(total)
    it = it.prev
  var b = it
  while it != nil:
    inc(total)
    it = it.prev
  for j in 1..total-i-(firstCalls-1): 
    if b != nil: b = b.prev
  if total != i:
    tempFrames[i] = nil
    inc(i)
  while b != nil and i <= high(tempFrames):
    tempFrames[i] = b
    inc(i)
    b = b.prev
  for j in countdown(i-1, 0):
    if tempFrames[j] == nil: 
      write(stdout, "(")
      write(stdout, (total-i-1))
      write(stdout, " calls omitted) ...")
    else:
      write(stdout, tempFrames[j].filename)
      if tempFrames[j].line > 0:
        write(stdout, '(')
        write(stdout, tempFrames[j].line)
        write(stdout, ')')
      write(stdout, ' ')
      write(stdout, tempFrames[j].procname)
    write(stdout, "\n")
  
proc checkWatchpoints =
  let L = WatchpointsLen
  for i in 0.. <L:
    let newHash = genericHash(Watchpoints[i].address, Watchpoints[i].typ)
    if newHash != Watchpoints[i].oldValue:
      dbgWriteStackTrace(framePtr)
      debugOut(Watchpoints[i].name)
      Watchpoints[i].oldValue = newHash
      
proc endb(line: int) {.compilerproc.} =
  # This proc is called before every Nimrod code line!
  # Thus, it must have as few parameters as possible to keep the
  # code size small!
  # Check if we are at an enabled breakpoint or "in the mood"
  if framePtr == nil: return
  let oldState = dbgState
  #dbgState = dbOff
  #if oldState != dbOff: 
  checkWatchpoints()
  framePtr.line = line # this is done here for smaller code size!
  if dbgLineHook != nil: dbgLineHook()
  case oldState
  of dbStepInto:
    # we really want the command prompt here:
    dbgShowExecutionPoint()
    CommandPrompt()
  of dbSkipCurrent, dbStepOver: # skip current routine
    if framePtr == dbgSkipToFrame:
      dbgShowExecutionPoint()
      CommandPrompt()
    else: # breakpoints are wanted though (I guess)
      checkForBreakpoint()
  of dbBreakpoints: # debugger is only interested in breakpoints
    checkForBreakpoint()
  else: nil

proc initDebugger {.inline.} =
  dbgState = dbStepInto
  dbgUser.len = 1
  dbgUser.data[0] = 's'

