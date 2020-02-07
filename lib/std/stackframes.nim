const NimStackTrace = compileOption("stacktrace")

template procName*(): string =
  ## returns current C/C++ function name
  when defined(c) or defined(cpp):
    var name {.inject.}: cstring
    {.emit: "`name` = __func__;".}
    $name

template getPFrame*(): PFrame =
  ## avoids a function call (unlike `getFrame()`)
  block:
    when NimStackTrace:
      var framePtr {.inject.}: PFrame
      {.emit: "`framePtr` = &FR_;".}
      framePtr

template setFrameMsg*(msg: string) =
  ## attach a msg to current PFrame. This can be called multiple times
  ## in a given PFrame.
  when NimStackTrace:
    block:
      var fr {.inject.}: PFrame
      {.emit: "`fr` = &FR_;".}
      # consider setting a custom upper limit on size (analog to stack overflow)
      const prefix = " " # to format properly
      frameMsgBuf.setLen fr.frameMsgLen
      frameMsgBuf.add prefix
      frameMsgBuf.add msg
      fr.frameMsgLen += prefix.len + msg.len
