const NimStackTrace = compileOption("stacktrace")
const NimStackTraceMsgs = compileOption("stacktraceMsgs")

template procName*(): string =
  ## returns current C/C++ function name
  when defined(c) or defined(cpp):
    var name {.inject, noinit.}: cstring
    {.emit: "`name` = __func__;".}
    $name

template getCurrentFrameIndex*(): untyped = getCurrentFrameIndexInternal()
template getCurrentFrame*(): PFrame =
  # make this this doesn't create a function call
  getCurrentFrameInternal()

template setFrameMsg*(msg: string, prefix = " ") =
  ## attach a msg to current `PFrame`. This can be called multiple times
  ## in a given PFrame. Noop unless passing --stacktraceMsgs and --stacktrace
  when NimStackTrace and NimStackTraceMsgs:
    block:
      let msg2 = msg # in case it changes the frame, or invalidates due to realloc; TODO: shallow?
      var fr = getCurrentFrame()
      # consider setting a custom upper limit on size (analog to stack overflow)
      frameMsgBuf.setLen fr.frameMsgLen
      frameMsgBuf.add prefix
      frameMsgBuf.add msg2
      fr.frameMsgLen = frameMsgBuf.len
