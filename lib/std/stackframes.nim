const NimStackTrace = compileOption("stacktrace")

template procName*(): string =
  var name {.inject.}: cstring
  {.emit: "`name` = __func__;".}
  $name
  # import std/strutils
  # ($name).rsplit('_', 1)[0]

# TODO:proc getFrame*(): PFrame {.compilerRtl, inl.} = framePtr
template getPFrame*(): PFrame =
  block:
    # note: PFrame.calldepth (among other fields...) seems useful
    when NimStackTrace:
      # IMPROVE: this does a double pointer copy (not a huge deal but still)
      var framePtr {.inject.}: PFrame
      {.emit: "`framePtr` = &FR_;".}
      framePtr

template setFrameMsg*(msg: string) =
  ## attach a msg to current PFrame. This can be called multiple times
  ## in a given PFrame.
  when NimStackTrace:
    let fr = getPFrame()
    # let fr = getFrame()
    # let fr = framePtr
    # TODO: instead realloc etc; TODO: also, js
    # TODO: set an upper limit? maybe not needed unless stack grows large AND lots of msgs are written
    frameMsgBuf.setLen fr.frameMsgLen
    frameMsgBuf.add msg
    fr.frameMsgLen += msg.len
