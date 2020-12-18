import terminal, strutils, strformat, options
type MsgColor* = enum
  mcError, mcWarn, mcHint, mcExpected, mcDefault, mcHighlight

# May want to also add styling for each of these
const defaultColors: array[MsgColor, ForegroundColor] = [fgRed, fgYellow, fgGreen, fgBlue, fgDefault, fgMagenta] 

proc colorError*(msg: string, col: MsgColor, c: ConfigRef): string =
  if optUseColors in c.globalOptions:
    fmt"{defaultColors[col].ansiForegroundColorCode}{msg}{ansiResetCode}"
  else:
    msg