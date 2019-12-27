discard """
  errormsg: "invalid indentation"
  file: "tinvwhen.nim"
  line: 11
"""
# This was parsed even though it should not!

proc chdir(path: cstring): cint {.importc: "chdir", header: "dirHeader".}

proc getcwd(buf: cstring, buflen: cint): cstring
    when defined(unix): {.importc: "getcwd", header: "<unistd.h>".} #ERROR_MSG invalid indentation
    elif defined(windows): {.importc: "getcwd", header: "<direct.h>"}
    else: {.error: "os library not ported to your OS. Please help!".}
