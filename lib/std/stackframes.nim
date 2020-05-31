const NimStackTrace = compileOption("stacktrace")
const NimStackTraceMsgs = compileOption("stacktraceMsgs")

template procName*(): string =
  ## returns current C/C++ function name
  when defined(c) or defined(cpp):
    var name {.inject, noinit.}: cstring
    {.emit: "`name` = __func__;".}
    $name

template getPFrame*(): PFrame =
  ## avoids a function call (unlike `getFrame()`)
  block:
    when NimStackTrace:
      var framePtr {.inject, noinit.}: PFrame
      {.emit: "`framePtr` = &FR_;".}
      framePtr

template setFrameMsg*(msg: string, prefix = " ") =
  ## attach a msg to current `PFrame`. This can be called multiple times
  ## in a given PFrame. Noop unless passing --stacktraceMsgs and --stacktrace
  when NimStackTrace and NimStackTraceMsgs:
    block:
      var fr {.inject, noinit.}: PFrame
      {.emit: "`fr` = &FR_;".}
      # consider setting a custom upper limit on size (analog to stack overflow)
      frameMsgBuf.setLen fr.frameMsgLen
      frameMsgBuf.add prefix
      frameMsgBuf.add msg
      fr.frameMsgLen += prefix.len + msg.len
