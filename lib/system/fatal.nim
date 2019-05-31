{.push profiler: off.}
when hostOS == "standalone":
  include "$projectpath/panicoverride"

  proc sysFatal(exceptn: typedesc, message: string) {.inline.} =
    panic(message)

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline.} =
    rawoutput(message)
    panic(arg)

elif defined(nimQuirky) and not defined(nimscript):
  import ansi_c

  proc name(t: typedesc): string {.magic: "TypeTrait".}

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noReturn.} =
    var buf = newStringOfCap(200)
    add(buf, "Error: unhandled exception: ")
    add(buf, message)
    add(buf, arg)
    add(buf, " [")
    add(buf, name exceptn)
    add(buf, "]")
    cstderr.rawWrite buf
    quit 1

  proc sysFatal(exceptn: typedesc, message: string) {.inline, noReturn.} =
    sysFatal(exceptn, message, "")

else:
  proc sysFatal(exceptn: typedesc, message: string) {.inline, noReturn.} =
    when declared(owned):
      var e: owned(ref exceptn)
    else:
      var e: ref exceptn
    new(e)
    e.msg = message
    raise e

  proc sysFatal(exceptn: typedesc, message, arg: string) {.inline, noReturn.} =
    when declared(owned):
      var e: owned(ref exceptn)
    else:
      var e: ref exceptn
    new(e)
    e.msg = message & arg
    raise e
{.pop.}
