#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.push profiler: off.}

when hostOS == "standalone":
  proc name(t: typedesc): string {.magic: "TypeTrait".}

  type PanicCallback* = proc(exceptionName: string, message: string, arg: string)

  var panicCallback: PanicCallback

  proc setPanicCallback*(a: PanicCallback) =
    ## this must be called at least once and is used by `sysFatal`; not thread safe.
    panicCallback = a

  proc sysFatal*(exceptn: typedesc, message: string) {.inline.} =
    # assumes `panicCallback != nil`
    panicCallback(name(exceptn), message, "")

  proc sysFatal*(exceptn: typedesc, message, arg: string) {.inline.} =
    # assumes `panicCallback != nil`
    panicCallback(name(exceptn), message, arg)

elif (defined(nimQuirky) or defined(nimPanics)) and not defined(nimscript):
  import system/ansi_c

  proc name(t: typedesc): string {.magic: "TypeTrait".}

  proc sysFatal*(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
    writeStackTrace()
    var buf = newStringOfCap(200)
    add(buf, "Error: unhandled exception: ")
    add(buf, message)
    add(buf, arg)
    add(buf, " [")
    add(buf, name exceptn)
    add(buf, "]\n")
    cstderr.rawWrite buf
    quit 1

  proc sysFatal*(exceptn: typedesc, message: string) {.inline, noreturn.} =
    sysFatal(exceptn, message, "")

else:
  proc sysFatal*(exceptn: typedesc, message: string) {.inline, noreturn.} =
    raise (ref exceptn)(msg: message)

  proc sysFatal*(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
    raise (ref exceptn)(msg: message & arg)

{.pop.}
