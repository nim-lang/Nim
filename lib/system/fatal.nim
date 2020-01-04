#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

{.push profiler: off.}

when defined(nimHasExceptionsQuery):
  const gotoBasedExceptions = compileOption("exceptions", "goto")
else:
  const gotoBasedExceptions = false

when hostOS == "standalone":
  include "$projectpath/panicoverride"

  proc sysFatal(exceptn: typedesc, message: string) {.inline.} =
    panic(message)

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline.} =
    rawoutput(message)
    panic(arg)

elif (defined(nimQuirky) or gotoBasedExceptions) and not defined(nimscript):
  import ansi_c

  proc name(t: typedesc): string {.magic: "TypeTrait".}

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
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

  proc sysFatal(exceptn: typedesc, message: string) {.inline, noreturn.} =
    sysFatal(exceptn, message, "")

else:
  proc sysFatal(exceptn: typedesc, message: string) {.inline, noreturn.} =
    when declared(owned):
      var e: owned(ref exceptn)
    else:
      var e: ref exceptn
    new(e)
    e.msg = message
    raise e

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noreturn.} =
    when declared(owned):
      var e: owned(ref exceptn)
    else:
      var e: ref exceptn
    new(e)
    e.msg = message & arg
    raise e
{.pop.}
