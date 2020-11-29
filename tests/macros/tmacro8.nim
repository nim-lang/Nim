# issue #8573

import
  macros,
  strutils,
  terminal

type LogSeverity* = enum
  sevError = "Error"
  sevWarn  = "Warn"
  sevInfo  = "Info"
  sevDebug = "Debug"

macro log*(severity: static[LogSeverity], group: static[string], m: varargs[typed]): untyped =
  let sevStr   = align("[" & toUpperAscii($severity) & "] ", 8)
  let sevColor = case severity
    of sevError: fgRed
    of sevWarn:  fgYellow
    of sevInfo:  fgWhite
    of sevDebug: fgBlack

  let groupStr = "[" & $group & "] "

  result = quote do:
    setStyle({ styleBright })
    setForegroundColor(sevColor) # <==
    write(stdout, sevStr)

    setStyle({ styleDim })
    setForegroundColor(fgWhite)
    write(stdout, groupStr)

  let wl = newCall(bindSym"styledWriteLine", bindSym"stdout")
  for arg in m: wl.add(arg)
  result.add(wl)
