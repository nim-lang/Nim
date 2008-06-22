# This was parsed even though it should not!

proc chdir(path: CString): cint {.import: "chdir", header: "dirHeader".}

proc getcwd(buf: CString, buflen: cint): CString
    when defined(unix): {.import: "getcwd", header: "<unistd.h>".} #ERROR
    elif defined(windows): {.import: "getcwd", header: "<direct.h>"}
    else: {.error: "os library not ported to your OS. Please help!".}
