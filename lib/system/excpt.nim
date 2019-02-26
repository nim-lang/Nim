#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Exception handling code. Carefully coded so that tiny programs which do not
# use the heap (and nor exceptions) do not include the GC or memory allocator.

var
  errorMessageWriter*: (proc(msg: string) {.tags: [WriteIOEffect], benign,
                                            nimcall.})
    ## Function that will be called
    ## instead of stdmsg.write when printing stacktrace.
    ## Unstable API.

proc c_fwrite(buf: pointer, size, n: csize, f: CFilePtr): cint {.
  importc: "fwrite", header: "<stdio.h>".}

proc rawWrite(f: CFilePtr, s: cstring) {.compilerproc, nonreloadable, hcrInline.} =
  # we cannot throw an exception here!
  discard c_fwrite(s, 1, s.len, f)

when not defined(windows) or not defined(guiapp):
  proc writeToStdErr(msg: cstring) = rawWrite(cstderr, msg)

else:
  proc MessageBoxA(hWnd: cint, lpText, lpCaption: cstring, uType: int): int32 {.
    header: "<windows.h>", nodecl.}

  proc writeToStdErr(msg: cstring) =
    discard MessageBoxA(0, msg, nil, 0)

proc showErrorMessage(data: cstring) {.gcsafe.} =
  if errorMessageWriter != nil:
    errorMessageWriter($data)
  else:
    when defined(genode):
      # stderr not available by default, use the LOG session
      echo data
    else:
      writeToStdErr(data)

proc quitOrDebug() {.inline.} =
  when not defined(endb):
    quit(1)
  else:
    endbStep() # call the debugger

proc chckIndx(i, a, b: int): int {.inline, compilerproc, benign.}
proc chckRange(i, a, b: int): int {.inline, compilerproc, benign.}
proc chckRangeF(x, a, b: float): float {.inline, compilerproc, benign.}
proc chckNil(p: pointer) {.noinline, compilerproc, benign.}

type
  GcFrame = ptr GcFrameHeader
  GcFrameHeader {.compilerproc.} = object
    len: int
    prev: ptr GcFrameHeader

var
  framePtr {.threadvar.}: PFrame
  excHandler {.threadvar.}: PSafePoint
    # list of exception handlers
    # a global variable for the root of all try blocks
  currException {.threadvar.}: ref Exception
  raiseCounter {.threadvar.}: uint

  gcFramePtr {.threadvar.}: GcFrame

type
  FrameState = tuple[gcFramePtr: GcFrame, framePtr: PFrame,
                     excHandler: PSafePoint, currException: ref Exception]

proc getFrameState*(): FrameState {.compilerRtl, inl.} =
  return (gcFramePtr, framePtr, excHandler, currException)

proc setFrameState*(state: FrameState) {.compilerRtl, inl.} =
  gcFramePtr = state.gcFramePtr
  framePtr = state.framePtr
  excHandler = state.excHandler
  currException = state.currException

proc getFrame*(): PFrame {.compilerRtl, inl.} = framePtr

proc popFrame {.compilerRtl, inl.} =
  framePtr = framePtr.prev

when false:
  proc popFrameOfAddr(s: PFrame) {.compilerRtl.} =
    var it = framePtr
    if it == s:
      framePtr = framePtr.prev
    else:
      while it != nil:
        if it == s:
          framePtr = it.prev
          break
        it = it.prev

proc setFrame*(s: PFrame) {.compilerRtl, inl.} =
  framePtr = s

proc getGcFrame*(): GcFrame {.compilerRtl, inl.} = gcFramePtr
proc popGcFrame*() {.compilerRtl, inl.} = gcFramePtr = gcFramePtr.prev
proc setGcFrame*(s: GcFrame) {.compilerRtl, inl.} = gcFramePtr = s
proc pushGcFrame*(s: GcFrame) {.compilerRtl, inl.} =
  s.prev = gcFramePtr
  zeroMem(cast[pointer](cast[int](s)+%sizeof(GcFrameHeader)), s.len*sizeof(pointer))
  gcFramePtr = s

proc pushSafePoint(s: PSafePoint) {.compilerRtl, inl.} =
  s.hasRaiseAction = false
  s.prev = excHandler
  excHandler = s

proc popSafePoint {.compilerRtl, inl.} =
  excHandler = excHandler.prev

proc pushCurrentException(e: ref Exception) {.compilerRtl, inl.} =
  e.up = currException
  currException = e

proc popCurrentException {.compilerRtl, inl.} =
  currException = currException.up

proc popCurrentExceptionEx(id: uint) {.compilerRtl.} =
  # in cpp backend exceptions can pop-up in the different order they were raised, example #5628
  if currException.raiseId == id:
    currException = currException.up
  else:
    var cur = currException.up
    var prev = currException
    while cur != nil and cur.raiseId != id:
      prev = cur
      cur = cur.up
    if cur == nil:
      showErrorMessage("popCurrentExceptionEx() exception was not found in the exception stack. Aborting...")
      quitOrDebug()
    prev.up = cur.up

proc closureIterSetupExc(e: ref Exception) {.compilerproc, inline.} =
  if not e.isNil:
    currException = e

# some platforms have native support for stack traces:
const
  nativeStackTraceSupported* = (defined(macosx) or defined(linux)) and
                              not NimStackTrace
  hasSomeStackTrace = NimStackTrace or
    defined(nativeStackTrace) and nativeStackTraceSupported

when defined(nativeStacktrace) and nativeStackTraceSupported:
  type
    TDl_info {.importc: "Dl_info", header: "<dlfcn.h>",
               final, pure.} = object
      dli_fname: cstring
      dli_fbase: pointer
      dli_sname: cstring
      dli_saddr: pointer

  proc backtrace(symbols: ptr pointer, size: int): int {.
    importc: "backtrace", header: "<execinfo.h>".}
  proc dladdr(addr1: pointer, info: ptr TDl_info): int {.
    importc: "dladdr", header: "<dlfcn.h>".}

  when not hasThreadSupport:
    var
      tempAddresses: array[0..127, pointer] # should not be alloc'd on stack
      tempDlInfo: TDl_info

  proc auxWriteStackTraceWithBacktrace(s: var string) =
    when hasThreadSupport:
      var
        tempAddresses: array[0..127, pointer] # but better than a threadvar
        tempDlInfo: TDl_info
    # This is allowed to be expensive since it only happens during crashes
    # (but this way you don't need manual stack tracing)
    var size = backtrace(cast[ptr pointer](addr(tempAddresses)),
                         len(tempAddresses))
    var enabled = false
    for i in 0..size-1:
      var dlresult = dladdr(tempAddresses[i], addr(tempDlInfo))
      if enabled:
        if dlresult != 0:
          var oldLen = s.len
          add(s, tempDlInfo.dli_fname)
          if tempDlInfo.dli_sname != nil:
            for k in 1..max(1, 25-(s.len-oldLen)): add(s, ' ')
            add(s, tempDlInfo.dli_sname)
        else:
          add(s, '?')
        add(s, "\n")
      else:
        if dlresult != 0 and tempDlInfo.dli_sname != nil and
            c_strcmp(tempDlInfo.dli_sname, "signalHandler") == 0'i32:
          # Once we're past signalHandler, we're at what the user is
          # interested in
          enabled = true

when not hasThreadSupport:
  var
    tempFrames: array[0..127, PFrame] # should not be alloc'd on stack

const
  reraisedFromBegin = -10
  reraisedFromEnd = -100

template reraisedFrom(z): untyped =
  StackTraceEntry(procname: nil, line: z, filename: nil)

proc auxWriteStackTrace(f: PFrame; s: var seq[StackTraceEntry]) =
  var
    it = f
    i = 0
  while it != nil:
    inc(i)
    it = it.prev
  var last = i-1
  when true: # not defined(gcDestructors):
    if s.len == 0:
      s = newSeq[StackTraceEntry](i)
    else:
      last = s.len + i - 1
      s.setLen(last+1)
  it = f
  while it != nil:
    s[last] = StackTraceEntry(procname: it.procname,
                              line: it.line,
                              filename: it.filename)
    it = it.prev
    dec last

template addFrameEntry(s, f: untyped) =
  var oldLen = s.len
  add(s, f.filename)
  if f.line > 0:
    add(s, '(')
    add(s, $f.line)
    add(s, ')')
  for k in 1..max(1, 25-(s.len-oldLen)): add(s, ' ')
  add(s, f.procname)
  add(s, "\n")

proc `$`(s: seq[StackTraceEntry]): string =
  result = newStringOfCap(2000)
  for i in 0 .. s.len-1:
    if s[i].line == reraisedFromBegin: result.add "[[reraised from:\n"
    elif s[i].line == reraisedFromEnd: result.add "]]\n"
    else: addFrameEntry(result, s[i])

proc auxWriteStackTrace(f: PFrame, s: var string) =
  when hasThreadSupport:
    var
      tempFrames: array[0..127, PFrame] # but better than a threadvar
  const
    firstCalls = 32
  var
    it = f
    i = 0
    total = 0
  # setup long head:
  while it != nil and i <= high(tempFrames)-firstCalls:
    tempFrames[i] = it
    inc(i)
    inc(total)
    it = it.prev
  # go up the stack to count 'total':
  var b = it
  while it != nil:
    inc(total)
    it = it.prev
  var skipped = 0
  if total > len(tempFrames):
    # skip N
    skipped = total-i-firstCalls+1
    for j in 1..skipped:
      if b != nil: b = b.prev
    # create '...' entry:
    tempFrames[i] = nil
    inc(i)
  # setup short tail:
  while b != nil and i <= high(tempFrames):
    tempFrames[i] = b
    inc(i)
    b = b.prev
  for j in countdown(i-1, 0):
    if tempFrames[j] == nil:
      add(s, "(")
      add(s, $skipped)
      add(s, " calls omitted) ...\n")
    else:
      addFrameEntry(s, tempFrames[j])

proc stackTraceAvailable*(): bool

when hasSomeStackTrace:
  proc rawWriteStackTrace(s: var string) =
    when NimStackTrace:
      if framePtr == nil:
        add(s, "No stack traceback available\n")
      else:
        add(s, "Traceback (most recent call last)\n")
        auxWriteStackTrace(framePtr, s)
    elif defined(nativeStackTrace) and nativeStackTraceSupported:
      add(s, "Traceback from system (most recent call last)\n")
      auxWriteStackTraceWithBacktrace(s)
    else:
      add(s, "No stack traceback available\n")

  proc rawWriteStackTrace(s: var seq[StackTraceEntry]) =
    when NimStackTrace:
      auxWriteStackTrace(framePtr, s)
    else:
      s = @[]

  proc stackTraceAvailable(): bool =
    when NimStackTrace:
      if framePtr == nil:
        result = false
      else:
        result = true
    elif defined(nativeStackTrace) and nativeStackTraceSupported:
      result = true
    else:
      result = false
else:
  proc stackTraceAvailable*(): bool = result = false

var onUnhandledException*: (proc (errorMsg: string) {.
  nimcall.}) ## set this error \
  ## handler to override the existing behaviour on an unhandled exception.
  ## The default is to write a stacktrace to ``stderr`` and then call ``quit(1)``.
  ## Unstable API.

template unhandled(buf, body) =
  if onUnhandledException != nil:
    onUnhandledException($buf)
  else:
    body

proc raiseExceptionAux(e: ref Exception) =
  if localRaiseHook != nil:
    if not localRaiseHook(e): return
  if globalRaiseHook != nil:
    if not globalRaiseHook(e): return
  when defined(cpp) and not defined(noCppExceptions):
    pushCurrentException(e)
    raiseCounter.inc
    if raiseCounter == 0:
      raiseCounter.inc # skip zero at overflow
    e.raiseId = raiseCounter
    {.emit: "`e`->raise();".}
  elif defined(nimQuirky):
    pushCurrentException(e)
  else:
    if excHandler != nil:
      if not excHandler.hasRaiseAction or excHandler.raiseAction(e):
        pushCurrentException(e)
        c_longjmp(excHandler.context, 1)
    else:
      when hasSomeStackTrace:
        var buf = newStringOfCap(2000)
        if e.trace.len == 0: rawWriteStackTrace(buf)
        else: add(buf, $e.trace)
        add(buf, "Error: unhandled exception: ")
        add(buf, e.msg)
        add(buf, " [")
        add(buf, $e.name)
        add(buf, "]\n")
        unhandled(buf):
          showErrorMessage(buf)
          quitOrDebug()
      else:
        # ugly, but avoids heap allocations :-)
        template xadd(buf, s, slen) =
          if L + slen < high(buf):
            copyMem(addr(buf[L]), cstring(s), slen)
            inc L, slen
        template add(buf, s) =
          xadd(buf, s, s.len)
        var buf: array[0..2000, char]
        var L = 0
        if e.trace.len != 0:
          add(buf, $e.trace) # gc allocation
        add(buf, "Error: unhandled exception: ")
        add(buf, e.msg)
        add(buf, " [")
        xadd(buf, e.name, e.name.len)
        add(buf, "]\n")
        when defined(nimNoArrayToCstringConversion):
          template tbuf(): untyped = addr buf
        else:
          template tbuf(): untyped = buf
        unhandled(tbuf()):
          showErrorMessage(tbuf())
          quitOrDebug()

proc raiseExceptionEx(e: ref Exception, ename, procname, filename: cstring, line: int) {.compilerRtl.} =
  if e.name.isNil: e.name = ename
  when hasSomeStackTrace:
    if e.trace.len == 0:
      rawWriteStackTrace(e.trace)
    elif framePtr != nil:
      e.trace.add reraisedFrom(reraisedFromBegin)
      auxWriteStackTrace(framePtr, e.trace)
      e.trace.add reraisedFrom(reraisedFromEnd)
  else:
    if procname != nil and filename != nil:
      e.trace.add StackTraceEntry(procname: procname, filename: filename, line: line)
  raiseExceptionAux(e)

proc raiseException(e: ref Exception, ename: cstring) {.compilerRtl.} =
  raiseExceptionEx(e, ename, nil, nil, 0)

proc reraiseException() {.compilerRtl.} =
  if currException == nil:
    sysFatal(ReraiseError, "no exception to reraise")
  else:
    raiseExceptionAux(currException)

proc writeStackTrace() =
  when hasSomeStackTrace:
    var s = ""
    rawWriteStackTrace(s)
    cast[proc (s: cstring) {.noSideEffect, tags: [], nimcall.}](showErrorMessage)(s)
  else:
    cast[proc (s: cstring) {.noSideEffect, tags: [], nimcall.}](showErrorMessage)("No stack traceback available\n")

proc getStackTrace(): string =
  when hasSomeStackTrace:
    result = ""
    rawWriteStackTrace(result)
  else:
    result = "No stack traceback available\n"

proc getStackTrace(e: ref Exception): string =
  if not isNil(e):
    result = $e.trace
  else:
    result = ""

proc getStackTraceEntries*(e: ref Exception): seq[StackTraceEntry] =
  ## Returns the attached stack trace to the exception ``e`` as
  ## a ``seq``. This is not yet available for the JS backend.
  when not defined(gcDestructors):
    shallowCopy(result, e.trace)
  else:
    result = move(e.trace)

const nimCallDepthLimit {.intdefine.} = 2000

proc callDepthLimitReached() {.noinline.} =
  writeStackTrace()
  showErrorMessage("Error: call depth limit reached in a debug build (" &
      $nimCallDepthLimit & " function calls). You can change it with " &
      "-d:nimCallDepthLimit=<int> but really try to avoid deep " &
      "recursions instead.\n")
  quitOrDebug()

proc nimFrame(s: PFrame) {.compilerRtl, inl.} =
  s.calldepth = if framePtr == nil: 0 else: framePtr.calldepth+1
  s.prev = framePtr
  framePtr = s
  if s.calldepth == nimCallDepthLimit: callDepthLimitReached()

when defined(endb):
  var
    dbgAborting: bool # whether the debugger wants to abort

when defined(cpp) and appType != "lib" and
    not defined(js) and not defined(nimscript) and
    hostOS != "standalone" and not defined(noCppExceptions):
  proc setTerminate(handler: proc() {.noconv.})
    {.importc: "std::set_terminate", header: "<exception>".}
  setTerminate proc() {.noconv.} =
    # Remove ourself as a handler, reinstalling the default handler.
    setTerminate(nil)

    when defined(genode):
      # stderr not available by default, use the LOG session
      echo currException.getStackTrace() & "Error: unhandled exception: " &
              currException.msg & " [" & $currException.name & "]\n"
    else:
      writeToStdErr currException.getStackTrace() & "Error: unhandled exception: " &
              currException.msg & " [" & $currException.name & "]\n"
    quit 1

when not defined(noSignalHandler) and not defined(useNimRtl):
  proc signalHandler(sign: cint) {.exportc: "signalHandler", noconv.} =
    template processSignal(s, action: untyped) {.dirty.} =
      if s == SIGINT: action("SIGINT: Interrupted by Ctrl-C.\n")
      elif s == SIGSEGV:
        action("SIGSEGV: Illegal storage access. (Attempt to read from nil?)\n")
      elif s == SIGABRT:
        when defined(endb):
          if dbgAborting: return # the debugger wants to abort
        action("SIGABRT: Abnormal termination.\n")
      elif s == SIGFPE: action("SIGFPE: Arithmetic error.\n")
      elif s == SIGILL: action("SIGILL: Illegal operation.\n")
      elif s == SIGBUS:
        action("SIGBUS: Illegal storage access. (Attempt to read from nil?)\n")
      else:
        block platformSpecificSignal:
          when declared(SIGPIPE):
            if s == SIGPIPE:
              action("SIGPIPE: Pipe closed.\n")
              break platformSpecificSignal
          action("unknown signal\n")

    # print stack trace and quit
    when defined(memtracker):
      logPendingOps()
    when hasSomeStackTrace:
      GC_disable()
      var buf = newStringOfCap(2000)
      rawWriteStackTrace(buf)
      processSignal(sign, buf.add) # nice hu? currying a la Nim :-)
      showErrorMessage(buf)
      GC_enable()
    else:
      var msg: cstring
      template asgn(y) =
        msg = y
      processSignal(sign, asgn)
      showErrorMessage(msg)
    when defined(endb): dbgAborting = true
    quit(1) # always quit when SIGABRT

  proc registerSignalHandler() =
    c_signal(SIGINT, signalHandler)
    c_signal(SIGSEGV, signalHandler)
    c_signal(SIGABRT, signalHandler)
    c_signal(SIGFPE, signalHandler)
    c_signal(SIGILL, signalHandler)
    c_signal(SIGBUS, signalHandler)
    when declared(SIGPIPE):
      c_signal(SIGPIPE, signalHandler)

  registerSignalHandler() # call it in initialization section

proc setControlCHook(hook: proc () {.noconv.}) =
  # ugly cast, but should work on all architectures:
  type SignalHandler = proc (sign: cint) {.noconv, benign.}
  c_signal(SIGINT, cast[SignalHandler](hook))

when not defined(noSignalHandler) and not defined(useNimRtl):
  proc unsetControlCHook() =
    # proc to unset a hook set by setControlCHook
    c_signal(SIGINT, signalHandler)
