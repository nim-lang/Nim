#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2009 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# This file implements the embedded debugger that can be linked
# with the application. We should not use dynamic memory here as that
# would interfere with the GC and trigger ON/OFF errors if the
# user program corrupts memory. Unfortunately, for dispaying
# variables we use the ``system.repr()`` proc which uses Nimrod
# strings and thus allocates memory from the heap. Pity, but
# I do not want to implement ``repr()`` twice. We also cannot deactivate
# the GC here as that might run out of memory too quickly...

type
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
    filename: string
    name: string     # name of breakpoint

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
  dbgInSignal: bool # wether the debugger is in the signal handler
  dbgIn: TFile # debugger input stream
  dbgUser: string = "s" # buffer for user input; first command is ``step_into``
                        # needs to be global cause we store the last command
                        # in it
  dbgState: TDbgState = dbStepInto # state of debugger
  dbgBP: array[0..127, TDbgBreakpoint] # breakpoints
  dbgBPlen: int = 0

  dbgSkipToFrame: PFrame # frame to be skipped to

  dbgGlobalData: TExtendedFrame # this reserves much space, but
                                # for now it is the most practical way

  maxDisplayRecDepth: int = 5 # do not display too much data!

proc findBreakpoint(name: string): int =
  # returns -1 if not found
  for i in countdown(dbgBPlen-1, 0):
    if name == dbgBP[i].name: return i
  return -1

proc ListBreakPoints() =
  write(stdout, "*** endb| Breakpoints:\n")
  for i in 0 .. dbgBPlen-1:
    write(stdout, dbgBP[i].name & ": " & $abs(dbgBP[i].low) & ".." &
                  $abs(dbgBP[i].high) & dbgBP[i].filename)
    if dbgBP[i].low < 0:
      write(stdout, " [disabled]\n")
    else:
      write(stdout, "\n")
  write(stdout, "***\n")

proc openAppend(filename: string): TFile =
  if open(result, filename, fmAppend):
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
  write(stream, "*** endb| Frame (" & $f.f.len &  " slots):\n")
  for i in 0 .. f.f.len-1:
    writeVariable(stream, f.slots[i])
  write(stream, "***\n")

proc ListVariables(stream: TFile, f: PExtendedFrame) =
  write(stream, "*** endb| Frame (" & $f.f.len & " slots):\n")
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
    write(stdout, "*** endb| (procedure name not available) ***\n")

proc dbgShowExecutionPoint() =
  ThreadGlobals()
  write(stdout, "*** endb| " & $(||framePtr).filename & 
                "(" & $(||framePtr).line & ") " & 
                $(||framePtr).procname & " ***\n")

when defined(windows) or defined(dos) or defined(os2):
  {.define: FileSystemCaseInsensitive.}

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
    when defined(FileSystemCaseInsensitive):
      if x >= 'A' and x <= 'Z': x = chr(ord(x) - ord('A') + ord('a'))
      if y >= 'A' and y <= 'Z': y = chr(ord(y) - ord('A') + ord('a'))
    if x != y: return false
    inc(i)
  return true

proc dbgBreakpointReached(line: int): int =
  ThreadGlobals()
  for i in 0..dbgBPlen-1:
    if line >= dbgBP[i].low and line <= dbgBP[i].high and
        fileMatches((||framePtr).filename, dbgBP[i].filename): return i
  return -1

proc scanAndAppendWord(src: string, a: var string, start: int): int =
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

proc scanWord(src: string, a: var string, start: int): int =
  a = ""
  result = scanAndAppendWord(src, a, start)

proc scanFilename(src: string, a: var string, start: int): int =
  result = start
  a = ""
  # skip whitespace:
  while src[result] in {'\t', ' '}: inc(result)
  while src[result] notin {'\t', ' ', '\0'}:
    add(a, src[result])
    inc(result)

proc scanNumber(src: string, a: var int, start: int): int =
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
c, continue             continue execution until the next breakpoint
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

proc hasExt(s: string): bool =
  # returns true if s has a filename extension
  for i in countdown(len(s)-1, 0):
    if s[i] == '.': return true
  return false

proc setBreakPoint(s: string, start: int) =
  ThreadGlobals()
  var dbgTemp: string
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
    dbgBP[x].low = (||framePtr).line
  i = scanNumber(s, dbgBP[x].high, i)
  if dbgBP[x].high == 0: # set to low:
    dbgBP[x].high = dbgBP[x].low
  i = scanFilename(s, dbgTemp, i)
  if not (dbgTemp.len == 0):
    if not hasExt(dbgTemp): add(dbgTemp, ".nim")
    dbgBP[x].filename = dbgTemp
  else: # use current filename
    dbgBP[x].filename = $(||framePtr).filename
  # skip whitespace:
  while s[i] in {' ', '\t'}: inc(i)
  if s[i] != '\0':
    dec(dbgBPLen) # remove buggy breakpoint
    InvalidCommand()

proc BreakpointSetEnabled(s: string, start, enabled: int) =
  var dbgTemp: string
  var i = scanWord(s, dbgTemp, start)
  if i <= start:
    InvalidCommand()
    return
  var x = findBreakpoint(dbgTemp)
  if x < 0: debugOut("[Warning] breakpoint does not exist ")
  elif enabled * dbgBP[x].low < 0: # signs are different?
    dbgBP[x].low = -dbgBP[x].low
    dbgBP[x].high = -dbgBP[x].high

proc dbgEvaluate(stream: TFile, s: string, start: int,
                 currFrame: PExtendedFrame) =
  var dbgTemp: string
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
  var j = findVariable(f, dbgTemp)
  if j < 0:
    debugOut("[Warning] could not find variable ")
    return
  writeVariable(stream, f.slots[j])

proc dbgOut(s: string, start: int, currFrame: PExtendedFrame) =
  var dbgTemp: string
  var i = scanFilename(s, dbgTemp, start)
  if dbgTemp.len == 0:
    InvalidCommand()
    return
  var stream = openAppend(dbgTemp)
  if stream == nil:
    debugOut("[Warning] could not open or create file ")
    return
  dbgEvaluate(stream, s, i, currFrame)
  close(stream)

proc dbgStackFrame(s: string, start: int, currFrame: PExtendedFrame) =
  var dbgTemp: string
  var i = scanFilename(s, dbgTemp, start)
  if dbgTemp.len == 0:
    # just write it to stdout:
    ListFrame(stdout, currFrame)
  else:
    var stream = openAppend(dbgTemp)
    if stream == nil:
      debugOut("[Warning] could not open or create file ")
      return
    ListFrame(stream, currFrame)
    close(stream)

proc CommandPrompt() =
  # if we return from this routine, user code executes again
  ThreadGlobals()
  var
    again = True
    dbgFramePtr = ||framePtr # for going down and up the stack
    dbgDown = 0 # how often we did go down

  while again:
    write(stdout, "*** endb| >>")
    var tmp = readLine(stdin)
    if tmp.len > 0: dbgUser = tmp
    # now look what we have to do:
    var dbgTemp: string
    var i = scanWord(dbgUser, dbgTemp, 0)
    case dbgTemp
    of "": InvalidCommand()
    of "s", "step":
      dbgState = dbStepInto
      again = false
    of "n", "next":
      dbgState = dbStepOver
      dbgSkipToFrame = ||framePtr
      again = false
    of "f", "skipcurrent":
      dbgState = dbSkipCurrent
      dbgSkipToFrame = (||framePtr).prev
      again = false
    of "c", "continue":
      dbgState = dbBreakpoints
      again = false
    of "i", "ignore":
      dbgState = dbOff
      again = false
    of "h", "help":
      dbgHelp()
    of "q", "quit":
      dbgState = dbQuiting
      dbgAborting = True
      again = false
      quit(1) # BUGFIX: quit with error code > 0
    of "e", "eval":
      dbgEvaluate(stdout, dbgUser, i, cast[PExtendedFrame](dbgFramePtr))
    of "o", "out":
      dbgOut(dbgUser, i, cast[PExtendedFrame](dbgFramePtr))
    of "stackframe":
      dbgStackFrame(dbgUser, i, cast[PExtendedFrame](dbgFramePtr))
    of "w", "where":
      dbgShowExecutionPoint()
    of "l", "locals":
      ListVariables(stdout, cast[PExtendedFrame](dbgFramePtr))
    of "g", "globals":
      ListVariables(stdout, addr(dbgGlobalData))
    of "u", "up":
      if dbgDown <= 0:
        debugOut("[Warning] cannot go up any further ")
      else:
        dbgFramePtr = ||framePtr
        for j in 0 .. dbgDown-2: # BUGFIX
          dbgFramePtr = dbgFramePtr.prev
        dec(dbgDown)
      dbgShowCurrentProc(dbgFramePtr)
    of "d", "down":
      if dbgFramePtr != nil:
        inc(dbgDown)
        dbgFramePtr = dbgFramePtr.prev
        dbgShowCurrentProc(dbgFramePtr)
      else:
        debugOut("[Warning] cannot go down any further ")
    of "bt", "backtrace":
      WriteStackTrace()
    of "b", "break":
      setBreakPoint(dbgUser, i)
    of "breakpoints":
      ListBreakPoints()
    of "disable":
      BreakpointSetEnabled(dbgUser, i, -1)
    of "enable":
      BreakpointSetEnabled(dbgUser, i, +1)
    of "maxdisplay":
      var parsed: int
      i = scanNumber(dbgUser, parsed, i)
      if dbgUser[i-1] in {'0'..'9'}:
        if parsed == 0: maxDisplayRecDepth = -1
        else: maxDisplayRecDepth = parsed
      else:
        InvalidCommand()
    else:
      InvalidCommand()

proc endbStep() =
  # we get into here if an unhandled exception has been raised
  # XXX: do not allow the user to run the program any further?
  # XXX: BUG: the frame is lost here!
  dbgShowExecutionPoint()
  CommandPrompt()

proc checkForBreakpoint() =
  ThreadGlobals()
  var i = dbgBreakpointReached((||framePtr).line)
  if i >= 0:
    write(stdout, "*** endb| reached ")
    write(stdout, dbgBP[i].name)
    write(stdout, " in ")
    write(stdout, (||framePtr).filename)
    write(stdout, "(")
    write(stdout, (||framePtr).line)
    write(stdout, ") ")
    write(stdout, (||framePtr).procname)
    write(stdout, " ***\n")
    CommandPrompt()

# interface to the user program:

proc dbgRegisterBreakpoint(line: int,
                           filename, name: cstring) {.compilerproc.} =
  var x = dbgBPlen
  inc(dbgBPlen)
  dbgBP[x].name = $name
  dbgBP[x].filename = $filename
  dbgBP[x].low = line
  dbgBP[x].high = line

proc dbgRegisterGlobal(name: cstring, address: pointer,
                       typ: PNimType) {.compilerproc.} =
  var i = dbgGlobalData.f.len
  if i >= high(dbgGlobalData.slots):
    debugOut("[Warning] cannot register global ")
    return
  dbgGlobalData.slots[i].name = name
  dbgGlobalData.slots[i].typ = typ
  dbgGlobalData.slots[i].address = address
  inc(dbgGlobalData.f.len)

proc endb(line: int) {.compilerproc.} =
  # This proc is called before every Nimrod code line!
  # Thus, it must have as few parameters as possible to keep the
  # code size small!
  # Check if we are at an enabled breakpoint or "in the mood"
  ThreadGlobals()
  (||framePtr).line = line # this is done here for smaller code size!
  if dbgLineHook != nil: dbgLineHook()
  case dbgState
  of dbStepInto:
    # we really want the command prompt here:
    dbgShowExecutionPoint()
    CommandPrompt()
  of dbSkipCurrent, dbStepOver: # skip current routine
    if ||framePtr == dbgSkipToFrame:
      dbgShowExecutionPoint()
      CommandPrompt()
    else: # breakpoints are wanted though (I guess)
      checkForBreakpoint()
  of dbBreakpoints: # debugger is only interested in breakpoints
    checkForBreakpoint()
  else: nil
