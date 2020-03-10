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

proc c_printf*(frmt: cstring): cint {.
  importc: "printf", header: "<stdio.h>", varargs, discardable.}

var
  errorMessageWriter*: (proc(msg: string) {.tags: [WriteIOEffect], benign,
                                            nimcall.})
    ## Function that will be called
    ## instead of `stdmsg.write` when printing stacktrace.
    ## Unstable API.

when not defined(windows) or not defined(guiapp):
  proc writeToStdErr(msg: cstring) = rawWrite(cstderr, msg)

else:
  proc MessageBoxA(hWnd: pointer, lpText, lpCaption: cstring, uType: int): int32 {.
    header: "<windows.h>", nodecl.}

  proc writeToStdErr(msg: cstring) =
    discard MessageBoxA(nil, msg, nil, 0)

proc showErrorMessage(data: cstring) {.gcsafe, raises: [].} =
  var toWrite = true
  if errorMessageWriter != nil:
    try:
      errorMessageWriter($data)
      toWrite = false
    except:
      discard
  if toWrite:
    when defined(genode):
      # stderr not available by default, use the LOG session
      echo data
    else:
      writeToStdErr(data)

proc chckIndx(i, a, b: int): int {.inline, compilerproc, benign.}
proc chckRange(i, a, b: int): int {.inline, compilerproc, benign.}
proc chckRangeF(x, a, b: float): float {.inline, compilerproc, benign.}
proc chckNil(p: pointer) {.noinline, compilerproc, benign.}

type
  GcFrame = ptr GcFrameHeader
  GcFrameHeader {.compilerproc.} = object
    len: int
    prev: ptr GcFrameHeader

type FrameIndex = uint
  # uint so it's unchecked? or push/pop overflow for this?
  # maybe use distinct?

type FrameData = object
  nimFrameGuard: bool
  tframesCap: int
  frameIndex: FrameIndex
  tframes: ptr UncheckedArray[TFrame]
    # we avoid `seq` as it'd create complications when resize is needed: we
    # want to avoid GC while in nimFrame

when not nimHasFrameFilename:
  template line(a: TFrame): int = cast[int](a.srcLocation)
  template procname(a: TFrame): cstring = "FAKE_procname"
  template filename(a: TFrame): cstring = "FAKE_filename"

var
  # frameData {.threadvar.}: FrameData
  frameData {.threadvar, exportc: "c_frameData".}: FrameData

  excHandler {.threadvar.}: PSafePoint
    # list of exception handlers
    # a global variable for the root of all try blocks
  currException {.threadvar.}: ref Exception
  gcFramePtr {.threadvar.}: GcFrame

when defined(cpp) and not defined(noCppExceptions) and not gotoBasedExceptions:
  var
    raiseCounter {.threadvar.}: uint

type
  FrameState = tuple[gcFramePtr: GcFrame, frameIndex: FrameIndex,
                     excHandler: PSafePoint, currException: ref Exception]

proc getFrameState*(): FrameState {.compilerRtl, inl.} =
  return (gcFramePtr, frameData.frameIndex, excHandler, currException)

proc setFrameState*(state: FrameState) {.compilerRtl, inl.} =
  gcFramePtr = state.gcFramePtr
  frameData.frameIndex = state.frameIndex
  excHandler = state.excHandler
  currException = state.currException

proc getFrame*(): FrameIndex {.compilerRtl, inl.} = frameData.frameIndex

proc popFrame {.compilerRtl, inl.} =
  frameData.frameIndex.dec

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

proc setFrame*(s: FrameIndex) {.compilerRtl, inl.} =
  frameData.frameIndex = s

proc getGcFrame*(): GcFrame {.compilerRtl, inl.} = gcFramePtr
proc popGcFrame*() {.compilerRtl, inl.} = gcFramePtr = gcFramePtr.prev
proc setGcFrame*(s: GcFrame) {.compilerRtl, inl.} = gcFramePtr = s
proc pushGcFrame*(s: GcFrame) {.compilerRtl, inl.} =
  s.prev = gcFramePtr
  zeroMem(cast[pointer](cast[int](s)+%sizeof(GcFrameHeader)), s.len*sizeof(pointer))
  gcFramePtr = s

proc pushSafePoint(s: PSafePoint) {.compilerRtl, inl.} =
  s.prev = excHandler
  excHandler = s

proc popSafePoint {.compilerRtl, inl.} =
  excHandler = excHandler.prev

proc pushCurrentException(e: sink(ref Exception)) {.compilerRtl, inl.} =
  e.up = currException
  currException = e
  #showErrorMessage "A"

proc popCurrentException {.compilerRtl, inl.} =
  currException = currException.up
  #showErrorMessage "B"

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
      quit(1)
    prev.up = cur.up

proc closureIterSetupExc(e: ref Exception) {.compilerproc, inline.} =
  currException = e

# some platforms have native support for stack traces:
const
  nativeStackTraceSupported* = (defined(macosx) or defined(linux)) and
                              not NimStackTrace
  hasSomeStackTrace = NimStackTrace or defined(nimStackTraceOverride) or
    (defined(nativeStackTrace) and nativeStackTraceSupported)

when defined(nimStackTraceOverride):
  type StackTraceOverrideProc* = proc (): string {.nimcall, noinline, benign, raises: [], tags: [].}
    ## Procedure type for overriding the default stack trace.

  var stackTraceOverrideGetTraceback: StackTraceOverrideProc = proc(): string {.noinline.} =
    result = "Stack trace override procedure not registered.\n"

  proc registerStackTraceOverride*(overrideProc: StackTraceOverrideProc) =
    ## Override the default stack trace inside rawWriteStackTrace() with your
    ## own procedure.
    stackTraceOverrideGetTraceback = overrideProc

  proc auxWriteStackTraceWithOverride(s: var string) =
    add(s, stackTraceOverrideGetTraceback())

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

when hasSomeStackTrace and not hasThreadSupport:
  var
    tempFrames: array[0..127, FrameIndex] # should not be alloc'd on stack

const
  reraisedFromBegin = -10
  reraisedFromEnd = -100

template reraisedFrom(z): untyped =
  StackTraceEntry(procname: nil, line: z, filename: nil)

proc auxWriteStackTrace(f: FrameIndex; s: var seq[StackTraceEntry]) =
  var
    it = f
    i = 0
  while it != 0:
    inc(i)
    it.dec
  var last = i-1
  when true: # not defined(gcDestructors):
    if s.len == 0:
      s = newSeq[StackTraceEntry](i)
    else:
      last = s.len + i - 1
      s.setLen(last+1)
  it = f
  while it != 0:
    s[last] = StackTraceEntry(procname: frameData.tframes[it].procname,
                              line: frameData.tframes[it].line,
                              filename: frameData.tframes[it].filename)
    it.dec
    dec last

template addFrameEntry(s: var string, f: StackTraceEntry|TFrame) =
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

when hasSomeStackTrace:

  proc auxWriteStackTrace(f: FrameIndex, s: var string) =
    when hasThreadSupport:
      var
        tempFrames: array[127, FrameIndex] # but better than a threadvar
    const
      firstCalls = 32
    var
      it = f
      i = 0
      total = 0
    # setup long head:
    while it != 0 and i <= high(tempFrames)-firstCalls:
      tempFrames[i] = it
      inc(i)
      inc(total)
      it.dec
    # go up the stack to count 'total':
    var b = it
    while it != 0:
      inc(total)
      it.dec
    var skipped = 0
    if total > len(tempFrames):
      # skip N
      skipped = total-i-firstCalls+1
      for j in 1..skipped:
        if b != 0: b.dec
      # create '...' entry:
      tempFrames[i] = 0 # CHECKME
      inc(i)
    # setup short tail:
    while b != 0 and i <= high(tempFrames):
      tempFrames[i] = b
      inc(i)
      b.dec
    for j in countdown(i-1, 0):
      if tempFrames[j] == 0:
        add(s, "(")
        add(s, $skipped)
        add(s, " calls omitted) ...\n")
      else:
        addFrameEntry(s, frameData.tframes[tempFrames[j]])

  proc stackTraceAvailable*(): bool

  proc rawWriteStackTrace(s: var string) =
    when defined(nimStackTraceOverride):
      add(s, "Traceback (most recent call last, using override)\n")
      auxWriteStackTraceWithOverride(s)
    elif NimStackTrace:
      if frameData.frameIndex == 0:
        add(s, "No stack traceback available v2\n")
      else:
        add(s, "Traceback (most recent call last)\n")
        auxWriteStackTrace(frameData.frameIndex, s)
    elif defined(nativeStackTrace) and nativeStackTraceSupported:
      add(s, "Traceback from system (most recent call last)\n")
      auxWriteStackTraceWithBacktrace(s)
    else:
      add(s, "No stack traceback available\n")

  proc rawWriteStackTrace(s: var seq[StackTraceEntry]) =
    when NimStackTrace:
      auxWriteStackTrace(frameData.frameIndex, s)
    else:
      s = @[]

  proc stackTraceAvailable(): bool =
    when defined(nimStackTraceOverride):
      result = true
    elif NimStackTrace:
      if frameData.frameIndex == 0:
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
  nimcall.}) ## Set this error \
  ## handler to override the existing behaviour on an unhandled exception.
  ##
  ## The default is to write a stacktrace to ``stderr`` and then call ``quit(1)``.
  ## Unstable API.

proc reportUnhandledErrorAux(e: ref Exception) {.nodestroy.} =
  when hasSomeStackTrace:
    var buf = newStringOfCap(2000)
    if e.trace.len == 0:
      rawWriteStackTrace(buf)
    else:
      var trace = $e.trace
      add(buf, trace)
      `=destroy`(trace)
    add(buf, "Error: unhandled exception: ")
    add(buf, e.msg)
    add(buf, " [")
    add(buf, $e.name)
    add(buf, "]\n")

    if onUnhandledException != nil:
      onUnhandledException(buf)
    else:
      showErrorMessage(buf)
    `=destroy`(buf)
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
      var trace = $e.trace
      add(buf, trace)
      `=destroy`(trace)
    add(buf, "Error: unhandled exception: ")
    add(buf, e.msg)
    add(buf, " [")
    xadd(buf, e.name, e.name.len)
    add(buf, "]\n")
    when defined(nimNoArrayToCstringConversion):
      template tbuf(): untyped = addr buf
    else:
      template tbuf(): untyped = buf

    if onUnhandledException != nil:
      onUnhandledException($tbuf())
    else:
      showErrorMessage(tbuf())

proc reportUnhandledError(e: ref Exception) {.nodestroy.} =
  if unhandledExceptionHook != nil:
    unhandledExceptionHook(e)
  when hostOS != "any":
    reportUnhandledErrorAux(e)
  else:
    discard()

proc nimLeaveFinally() {.compilerRtl.} =
  when defined(cpp) and not defined(noCppExceptions) and not gotoBasedExceptions:
    {.emit: "throw;".}
  else:
    if excHandler != nil:
      c_longjmp(excHandler.context, 1)
    else:
      reportUnhandledError(currException)
      quit(1)

when gotoBasedExceptions:
  var nimInErrorMode {.threadvar.}: int

  proc nimErrorFlag(): ptr int {.compilerRtl, inl.} =
    result = addr(nimInErrorMode)

  proc nimTestErrorFlag() {.compilerRtl.} =
    ## This proc must be called before ``currException`` is destroyed.
    ## It also must be called at the end of every thread to ensure no
    ## error is swallowed.
    if currException != nil:
      reportUnhandledError(currException)
      currException = nil
      quit(1)

proc raiseExceptionAux(e: sink(ref Exception)) {.nodestroy.} =
  if localRaiseHook != nil:
    if not localRaiseHook(e): return
  if globalRaiseHook != nil:
    if not globalRaiseHook(e): return
  when defined(cpp) and not defined(noCppExceptions) and not gotoBasedExceptions:
    if e == currException:
      {.emit: "throw;".}
    else:
      pushCurrentException(e)
      raiseCounter.inc
      if raiseCounter == 0:
        raiseCounter.inc # skip zero at overflow
      e.raiseId = raiseCounter
      {.emit: "`e`->raise();".}
  elif defined(nimQuirky) or gotoBasedExceptions:
    # XXX This check should likely also be done in the setjmp case below.
    if e != currException:
      pushCurrentException(e)
    when gotoBasedExceptions:
      inc nimInErrorMode
  else:
    if excHandler != nil:
      pushCurrentException(e)
      c_longjmp(excHandler.context, 1)
    else:
      reportUnhandledError(e)
      quit(1)

proc raiseExceptionEx(e: sink(ref Exception), ename, procname, filename: cstring,
                      line: int) {.compilerRtl, nodestroy.} =
  if e.name.isNil: e.name = ename
  when hasSomeStackTrace:
    when defined(nimStackTraceOverride):
      e.trace = @[]
    elif NimStackTrace:
      if e.trace.len == 0:
        rawWriteStackTrace(e.trace)
      elif frameData.frameIndex != 0:
        e.trace.add reraisedFrom(reraisedFromBegin)
        auxWriteStackTrace(frameData.frameIndex, e.trace)
        e.trace.add reraisedFrom(reraisedFromEnd)
  else:
    if procname != nil and filename != nil:
      e.trace.add StackTraceEntry(procname: procname, filename: filename, line: line)
  raiseExceptionAux(e)

proc raiseException(e: sink(ref Exception), ename: cstring) {.compilerRtl.} =
  raiseExceptionEx(e, ename, nil, nil, 0)

proc reraiseException() {.compilerRtl.} =
  if currException == nil:
    sysFatal(ReraiseError, "no exception to reraise")
  else:
    when gotoBasedExceptions:
      inc nimInErrorMode
    else:
      raiseExceptionAux(currException)

proc writeStackTrace() =
  when hasSomeStackTrace:
    var s = ""
    rawWriteStackTrace(s)
    cast[proc (s: cstring) {.noSideEffect, tags: [], nimcall, raises: [].}](showErrorMessage)(s)
  else:
    cast[proc (s: cstring) {.noSideEffect, tags: [], nimcall, raises: [].}](showErrorMessage)("No stack traceback available\n")

proc getStackTrace(): string =
  # c_printf("getStackTrace\n")
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
  when not defined(nimSeqsV2):
    shallowCopy(result, e.trace)
  else:
    result = move(e.trace)

proc getStackTraceEntries*(): seq[StackTraceEntry] =
  ## Returns the stack trace entries for the current stack trace.
  ## This is not yet available for the JS backend.
  when hasSomeStackTrace:
    rawWriteStackTrace(result)

const nimCallDepthLimit {.intdefine.} = 2000

proc callDepthLimitReached() {.noinline.} =
  writeStackTrace()
  showErrorMessage("Error: call depth limit reached in a debug build (" &
      $nimCallDepthLimit & " function calls). You can change it with " &
      "-d:nimCallDepthLimit=<int> but really try to avoid deep " &
      "recursions instead.\n")
  quit(1)

template nimFrameInc() =
  # TODO: how to ensure no GC used here? `noSideEffect and nogc` don't work for that
  frameData.frameIndex.inc
  # if frameData.nimFrameGuard:
  #   c_printf("nimFrame:%*s %s:%s %lld\n", frameIndex, "", filename, procname, frameIndex)
  #   return
  # frameData.nimFrameGuard = true
  if frameData.frameIndex == nimCallDepthLimit: callDepthLimitReached()

  if frameData.frameIndex >= cast[FrameIndex](frameData.tframesCap):
    const sz = sizeof(TFrame)
    let old = frameData.tframesCap
    if frameData.tframesCap == 0: frameData.tframesCap = 8
    else: frameData.tframesCap+=frameData.tframesCap
    proc c_realloc(p: pointer, newsize: csize_t): pointer {.importc: "realloc", header: "<stdlib.h>".}
    # tframes = cast[type(tframes)](realloc0(tframes, sz*old, sz*tframesCap))
    frameData.tframes = cast[type(frameData.tframes)](c_realloc(frameData.tframes, cast[csize_t](sz*frameData.tframesCap)))
  # frameData.nimFrameGuard = false

template currentFrame(): untyped = frameData.tframes[frameData.frameIndex]

when nimHasFrameFilename:
  proc nimFrame(procname, filename: cstring, line: int) {.compilerRtl, inl, raises: [].} =
    nimFrameInc()
    currentFrame.procname = procname
    currentFrame.filename = filename
    currentFrame.line = line
  proc nimLine(filename: cstring, line: int) {.compilerRtl, inl, raises: [].} =
    currentFrame.filename = filename
else:
  # proc nimFrameMapping(fileIndex: SrcLocation, ) {.compilerRtl, inl, raises: [].} =

  proc nimFrame(srcLocation: SrcLocation) {.compilerRtl, inl, raises: [].} =
    nimFrameInc()
    currentFrame.srcLocation = srcLocation
  proc nimLine(srcLocation: SrcLocation) {.compilerRtl, inl, raises: [].} =
    #[
    # TODO: compare apples to apples, eg wo nimLine only nimFrame
    TODO: no need for filename when we have nimFrame, since filename won't change
    SEE also:
    codegenDecl: "static __attribute__((__always_inline__)) $# $# $#"
    __attribute__ ((optimize(1)))

    TODO: could optimize here by not having to update `filename`, assuming constant in a proc; but handle special case where #line directive changes that
    ]#
    # c_printf "D20200308T182538\n"
    currentFrame.srcLocation = srcLocation

when defined(cpp) and appType != "lib" and not gotoBasedExceptions and
    not defined(js) and not defined(nimscript) and
    hostOS != "standalone" and not defined(noCppExceptions):

  type
    StdException {.importcpp: "std::exception", header: "<exception>".} = object

  proc what(ex: StdException): cstring {.importcpp: "((char *)#.what())".}

  proc setTerminate(handler: proc() {.noconv.})
    {.importc: "std::set_terminate", header: "<exception>".}

  setTerminate proc() {.noconv.} =
    # Remove ourself as a handler, reinstalling the default handler.
    setTerminate(nil)

    var msg = "Unknown error in unexpected exception handler"
    try:
      {.emit"#if !defined(_MSC_VER) || (_MSC_VER >= 1923)".}
      raise
      {.emit"#endif".}
    except Exception:
      msg = currException.getStackTrace() & "Error: unhandled exception: " &
        currException.msg & " [" & $currException.name & "]"
    except StdException as e:
      msg = "Error: unhandled cpp exception: " & $e.what()
    except:
      msg = "Error: unhandled unknown cpp exception"

    {.emit"#if defined(_MSC_VER) && (_MSC_VER < 1923)".}
    msg = "Error: unhandled unknown cpp exception"
    {.emit"#endif".}

    when defined(genode):
      # stderr not available by default, use the LOG session
      echo msg
    else:
      writeToStdErr msg & "\n"

    quit 1

when not defined(noSignalHandler) and not defined(useNimRtl):
  proc signalHandler(sign: cint) {.exportc: "signalHandler", noconv.} =
    template processSignal(s, action: untyped) {.dirty.} =
      if s == SIGINT: action("SIGINT: Interrupted by Ctrl-C.\n")
      elif s == SIGSEGV:
        action("SIGSEGV: Illegal storage access. (Attempt to read from nil?)\n")
      elif s == SIGABRT:
        action("SIGABRT: Abnormal termination.\n")
      elif s == SIGFPE: action("SIGFPE: Arithmetic error.\n")
      elif s == SIGILL: action("SIGILL: Illegal operation.\n")
      elif (when declared(SIGBUS): s == SIGBUS else: false):
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
      when not usesDestructors: GC_disable()
      var buf = newStringOfCap(2000)
      rawWriteStackTrace(buf)
      processSignal(sign, buf.add) # nice hu? currying a la Nim :-)
      showErrorMessage(buf)
      when not usesDestructors: GC_enable()
    else:
      var msg: cstring
      template asgn(y) =
        msg = y
      processSignal(sign, asgn)
      showErrorMessage(msg)
    quit(1) # always quit when SIGABRT

  proc registerSignalHandler() =
    c_signal(SIGINT, signalHandler)
    c_signal(SIGSEGV, signalHandler)
    c_signal(SIGABRT, signalHandler)
    c_signal(SIGFPE, signalHandler)
    c_signal(SIGILL, signalHandler)
    when declared(SIGBUS):
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
