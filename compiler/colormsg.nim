#
#
#           The Nim Compiler
#        (c) Copyright 2020 Nim Contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
# This module is for adding colour to error messages from the compiler,
# using strformat and terminal.

import terminal, strutils, strformat, options
type MsgColor* = enum
  mcError, mcWarn, mcHint, mcExpected, mcDefault, mcHighlight

# May want to also add styling for each of these
const defaultColors: array[MsgColor, ForegroundColor] = [fgRed, fgYellow, fgGreen, fgBlue, fgDefault, fgMagenta] 

proc colorMsg*(msg: string, col: MsgColor, c: ConfigRef): string =
  if optUseColors in c.globalOptions:
    fmt"{defaultColors[col].ansiForegroundColorCode}{msg}{ansiResetCode}"
  else:
    msg

template colorError*(msg: string, c: ConfigRef): string =
  msg.colorMsg(mcError, c)

template colorWarn*(msg: string, c: ConfigRef): string =
  msg.colorMsg(mcWarn, c)

template colorHint*(msg: string, c: ConfigRef): string =
  msg.colorMsg(mcHint, c)

template colorExpect*(msg: string, c: ConfigRef): string =
  msg.colorMsg(mcExpected, c)

template colorHighlight*(msg: string, c: ConfigRef): string =
  msg.colorMsg(mcHighlight, c)
