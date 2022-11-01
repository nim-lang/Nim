#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.push profiler: off.}


when defined(nimNoQuit):
  proc rawQuit*(errorcode: int = QuitSuccess) = discard "ignoring quit"

elif defined(genode):
  import genode/env

  var systemEnv {.exportc: runtimeEnvSym.}: GenodeEnvPtr

  proc rawQuit*(env: GenodeEnv; errorcode: int) {.magic: "Exit", noreturn,
    importcpp: "#->parent().exit(@); Genode::sleep_forever()", header: "<base/sleep.h>".}

  proc rawQuit*(errorcode: int = QuitSuccess) {.inline, noreturn.} =
    systemEnv.rawQuit(errorcode)


elif defined(js) and defined(nodejs) and not defined(nimscript):
  proc rawQuit*(errorcode: int = QuitSuccess) {.magic: "Exit",
    importc: "process.exit", noreturn.}

else:
  proc rawQuit*(errorcode: int = QuitSuccess) {.
    magic: "Exit", importc: "exit", header: "<stdlib.h>", noreturn.}


when hostOS == "standalone":
  include "$projectpath/panicoverride"

  func sysFatal*(exceptn: typedesc, message: string) {.inline.} =
    panic(message)

  func sysFatal*(exceptn: typedesc, message, arg: string) {.inline.} =
    rawoutput(message)
    panic(arg)

elif (defined(nimQuirky) or defined(nimPanics)) and not defined(nimscript):
  import system/ansi_c

  func name(t: typedesc): string {.magic: "TypeTrait".}

  func sysFatal*(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
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

  func sysFatal*(exceptn: typedesc, message: string) {.inline, noreturn.} =
    sysFatal(exceptn, message, "")

else:
  func sysFatal*(exceptn: typedesc, message: string) {.inline, noreturn.} =
    raise (ref exceptn)(msg: message)

  func sysFatal*(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
    raise (ref exceptn)(msg: message & arg)

{.pop.}
