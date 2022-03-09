discard """
  errormsg: "can raise an unlisted exception: Exception"
  line: 23
"""

{.push warningAsError[Effect]: on.}
{.experimental: "strictEffects".}

# bug #13905

proc atoi(v: cstring): cint {.importc: "atoi", cdecl, raises: [].}

type Conv = proc(v: cstring): cint {.cdecl, raises: [].}

var x: Conv = atoi

# bug #17475

type
  Callback = proc()

proc f(callback: Callback) {.raises: [].} =
  callback()

proc main =
  f(proc () = raise newException(IOError, "IO"))

main()
