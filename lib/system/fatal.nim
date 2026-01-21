#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.push profiler: off.}

const
  gotoBasedExceptions = compileOption("exceptions", "goto")
  quirkyExceptions = compileOption("exceptions", "quirky")

when hostOS == "standalone":
  type
    PanicProc* = proc(msg: string) {.nimcall.}
    RawOutputProc* = proc(msg: string) {.nimcall.}

  # These are set up from panicoverride.nim, which must be included
  # if `hostOS == "standalone"`, so they will always be set or a compile time
  # error will be generated.
  var panicImpl: PanicProc
  var rawOutputImpl: RawOutputProc

  template sysFatal(exceptn: typedesc[Defect], message: string) =
    {.cast(noSideEffect).}:
      {.cast(raises: []).}:
        {.cast(tags: []).}:
          panicImpl(message)

  template sysFatal(exceptn: typedesc[Defect], message, arg: string) =
    {.cast(noSideEffect).}:
      {.cast(raises: []).}:
        {.cast(tags: []).}:
          rawOutputImpl(message)
          panicImpl(arg)

elif quirkyExceptions and not defined(nimscript):
  import ansi_c

  func name(t: typedesc): string {.magic: "TypeTrait".}

  func sysFatal(exceptn: typedesc[Defect], message, arg: string) {.inline, noreturn.} =
    when nimvm:
      # TODO when doAssertRaises works in CT, add a test for it
      raise (ref exceptn)(msg: message & arg)
    else:
      {.noSideEffect.}:
        writeStackTrace()
        var buf = newStringOfCap(200)
        add(buf, "Error: unhandled exception: ")
        add(buf, message)
        add(buf, arg)
        add(buf, " [")
        add(buf, name exceptn)
        add(buf, "]\n")
        cstderr.rawWrite buf
      rawQuit 1

  func sysFatal(exceptn: typedesc[Defect], message: string) {.inline, noreturn.} =
    sysFatal(exceptn, message, "")

else:
  func sysFatal(exceptn: typedesc[Defect], message: string) {.inline, noreturn.} =
    raise (ref exceptn)(msg: message)

  func sysFatal(exceptn: typedesc[Defect], message, arg: string) {.inline, noreturn.} =
    raise (ref exceptn)(msg: message & arg)

{.pop.}
