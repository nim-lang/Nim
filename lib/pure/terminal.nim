#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains a few procedures to control the *terminal*
## (also called *console*). On UNIX, the implementation simply uses ANSI escape
## sequences and does not depend on any other module, on Windows it uses the
## Windows API.
## Changing the style is permanent even after program termination! Use the
## code ``system.addQuitProc(resetAttributes)`` to restore the defaults.

import macros

when defined(windows):
  import windows, os

  var
    conHandle: THandle
  # = createFile("CONOUT$", GENERIC_WRITE, 0, nil, OPEN_ALWAYS, 0, 0)

  block:
    var hTemp = GetStdHandle(STD_OUTPUT_HANDLE)
    if DuplicateHandle(GetCurrentProcess(), hTemp, GetCurrentProcess(),
                       addr(conHandle), 0, 1, DUPLICATE_SAME_ACCESS) == 0:
      OSError(OSLastError())

  proc getCursorPos(): tuple [x,y: int] =
    var c: TCONSOLE_SCREEN_BUFFER_INFO
    if GetConsoleScreenBufferInfo(conHandle, addr(c)) == 0: OSError(OSLastError())
    return (int(c.dwCursorPosition.x), int(c.dwCursorPosition.y))

  proc getAttributes(): int16 =
    var c: TCONSOLE_SCREEN_BUFFER_INFO
    # workaround Windows bugs: try several times
    if GetConsoleScreenBufferInfo(conHandle, addr(c)) != 0:
      return c.wAttributes
    return 0x70'i16 # ERROR: return white background, black text

  var
    oldAttr = getAttributes()

proc setCursorPos*(x, y: int) =
  ## sets the terminal's cursor to the (x,y) position. (0,0) is the
  ## upper left of the screen.
  when defined(windows):
    var c: TCoord
    c.x = int16(x)
    c.y = int16(y)
    if SetConsoleCursorPosition(conHandle, c) == 0: OSError(OSLastError())
  else:
    stdout.write("\e[" & $y & ';' & $x & 'f')

proc setCursorXPos*(x: int) =
  ## sets the terminal's cursor to the x position. The y position is
  ## not changed.
  when defined(windows):
    var scrbuf: TCONSOLE_SCREEN_BUFFER_INFO
    var hStdout = conHandle
    if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0: OSError(OSLastError())
    var origin = scrbuf.dwCursorPosition
    origin.x = int16(x)
    if SetConsoleCursorPosition(conHandle, origin) == 0: OSError(OSLastError())
  else:
    stdout.write("\e[" & $x & 'G')

when defined(windows):
  proc setCursorYPos*(y: int) =
    ## sets the terminal's cursor to the y position. The x position is
    ## not changed. **Warning**: This is not supported on UNIX!
    when defined(windows):
      var scrbuf: TCONSOLE_SCREEN_BUFFER_INFO
      var hStdout = conHandle
      if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0: OSError(OSLastError())
      var origin = scrbuf.dwCursorPosition
      origin.y = int16(y)
      if SetConsoleCursorPosition(conHandle, origin) == 0: OSError(OSLastError())
    else:
      nil

proc CursorUp*(count=1) =
  ## Moves the cursor up by `count` rows.
  when defined(windows):
    var p = getCursorPos()
    dec(p.y, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'A')

proc CursorDown*(count=1) =
  ## Moves the cursor down by `count` rows.
  when defined(windows):
    var p = getCursorPos()
    inc(p.y, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'B')

proc CursorForward*(count=1) =
  ## Moves the cursor forward by `count` columns.
  when defined(windows):
    var p = getCursorPos()
    inc(p.x, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'C')

proc CursorBackward*(count=1) =
  ## Moves the cursor backward by `count` columns.
  when defined(windows):
    var p = getCursorPos()
    dec(p.x, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'D')

when true:
  nil
else:
  proc EraseLineEnd* =
    ## Erases from the current cursor position to the end of the current line.
    when defined(windows):
      nil
    else:
      stdout.write("\e[K")

  proc EraseLineStart* =
    ## Erases from the current cursor position to the start of the current line.
    when defined(windows):
      nil
    else:
      stdout.write("\e[1K")

  proc EraseDown* =
    ## Erases the screen from the current line down to the bottom of the screen.
    when defined(windows):
      nil
    else:
      stdout.write("\e[J")

  proc EraseUp* =
    ## Erases the screen from the current line up to the top of the screen.
    when defined(windows):
      nil
    else:
      stdout.write("\e[1J")

proc EraseLine* =
  ## Erases the entire current line.
  when defined(windows):
    var scrbuf: TCONSOLE_SCREEN_BUFFER_INFO
    var numwrote: DWORD
    var hStdout = conHandle
    if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0: OSError(OSLastError())
    var origin = scrbuf.dwCursorPosition
    origin.x = 0'i16
    if SetConsoleCursorPosition(conHandle, origin) == 0: OSError(OSLastError())
    var ht = scrbuf.dwSize.Y - origin.Y
    var wt = scrbuf.dwSize.X - origin.X
    if FillConsoleOutputCharacter(hStdout,' ', ht*wt,
                                  origin, addr(numwrote)) == 0:
      OSError(OSLastError())
    if FillConsoleOutputAttribute(hStdout, scrbuf.wAttributes, ht * wt,
                                  scrbuf.dwCursorPosition, addr(numwrote)) == 0:
      OSError(OSLastError())
  else:
    stdout.write("\e[2K")
    setCursorXPos(0)

proc EraseScreen* =
  ## Erases the screen with the background colour and moves the cursor to home.
  when defined(windows):
    var scrbuf: TCONSOLE_SCREEN_BUFFER_INFO
    var numwrote: DWORD
    var origin: TCoord # is inititalized to 0, 0
    var hStdout = conHandle
    if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0: OSError(OSLastError())
    if FillConsoleOutputCharacter(hStdout, ' ', scrbuf.dwSize.X*scrbuf.dwSize.Y,
                                  origin, addr(numwrote)) == 0:
      OSError(OSLastError())
    if FillConsoleOutputAttribute(hStdout, scrbuf.wAttributes,
                                  scrbuf.dwSize.X * scrbuf.dwSize.Y,
                                  origin, addr(numwrote)) == 0:
      OSError(OSLastError())
    setCursorXPos(0)
  else:
    stdout.write("\e[2J")

proc ResetAttributes* {.noconv.} =
  ## resets all attributes; it is advisable to register this as a quit proc
  ## with ``system.addQuitProc(resetAttributes)``.
  when defined(windows):
    discard SetConsoleTextAttribute(conHandle, oldAttr)
  else:
    stdout.write("\e[0m")

type
  TStyle* = enum         ## different styles for text output
    styleBright = 1,     ## bright text
    styleDim,            ## dim text
    styleUnknown,        ## unknown
    styleUnderscore = 4, ## underscored text
    styleBlink,          ## blinking/bold text
    styleReverse = 7,    ## unknown
    styleHidden          ## hidden text

when not defined(windows):
  var
    # XXX: These better be thread-local
    gFG = 0
    gBG = 0

proc setStyle*(style: set[TStyle]) =
  ## sets the terminal style
  when defined(windows):
    var a = 0'i16
    if styleBright in style: a = a or int16(FOREGROUND_INTENSITY)
    if styleBlink in style: a = a or int16(BACKGROUND_INTENSITY)
    if styleReverse in style: a = a or 0x4000'i16 # COMMON_LVB_REVERSE_VIDEO
    if styleUnderscore in style: a = a or 0x8000'i16 # COMMON_LVB_UNDERSCORE
    discard SetConsoleTextAttribute(conHandle, a)
  else:
    for s in items(style):
      stdout.write("\e[" & $ord(s) & 'm')

proc WriteStyled*(txt: string, style: set[TStyle] = {styleBright}) =
  ## writes the text `txt` in a given `style`.
  when defined(windows):
    var old = getAttributes()
    setStyle(style)
    stdout.write(txt)
    discard SetConsoleTextAttribute(conHandle, old)
  else:
    setStyle(style)
    stdout.write(txt)
    resetAttributes()
    if gFG != 0:
      stdout.write("\e[" & $ord(gFG) & 'm')
    if gBG != 0:
      stdout.write("\e[" & $ord(gBG) & 'm')

type
  TForegroundColor* = enum ## terminal's foreground colors
    fgBlack = 30,          ## black
    fgRed,                 ## red
    fgGreen,               ## green
    fgYellow,              ## yellow
    fgBlue,                ## blue
    fgMagenta,             ## magenta
    fgCyan,                ## cyan
    fgWhite                ## white

  TBackgroundColor* = enum ## terminal's background colors
    bgBlack = 40,          ## black
    bgRed,                 ## red
    bgGreen,               ## green
    bgYellow,              ## yellow
    bgBlue,                ## blue
    bgMagenta,             ## magenta
    bgCyan,                ## cyan
    bgWhite                ## white

proc setForegroundColor*(fg: TForegroundColor, bright=false) =
  ## sets the terminal's foreground color
  when defined(windows):
    var old = getAttributes() and not 0x0007
    if bright:
      old = old or FOREGROUND_INTENSITY
    const lookup: array [TForegroundColor, int] = [
      0,
      (FOREGROUND_RED),
      (FOREGROUND_GREEN),
      (FOREGROUND_RED or FOREGROUND_GREEN),
      (FOREGROUND_BLUE),
      (FOREGROUND_RED or FOREGROUND_BLUE),
      (FOREGROUND_BLUE or FOREGROUND_GREEN),
      (FOREGROUND_BLUE or FOREGROUND_GREEN or FOREGROUND_RED)]
    discard SetConsoleTextAttribute(conHandle, toU16(old or lookup[fg]))
  else:
    gFG = ord(fg)
    if bright: inc(gFG, 60)
    stdout.write("\e[" & $gFG & 'm')

proc setBackgroundColor*(bg: TBackgroundColor, bright=false) =
  ## sets the terminal's background color
  when defined(windows):
    var old = getAttributes() and not 0x0070
    if bright:
      old = old or BACKGROUND_INTENSITY
    const lookup: array [TBackgroundColor, int] = [
      0,
      (BACKGROUND_RED),
      (BACKGROUND_GREEN),
      (BACKGROUND_RED or BACKGROUND_GREEN),
      (BACKGROUND_BLUE),
      (BACKGROUND_RED or BACKGROUND_BLUE),
      (BACKGROUND_BLUE or BACKGROUND_GREEN),
      (BACKGROUND_BLUE or BACKGROUND_GREEN or BACKGROUND_RED)]
    discard SetConsoleTextAttribute(conHandle, toU16(old or lookup[bg]))
  else:
    gBG = ord(bg)
    if bright: inc(gBG, 60)
    stdout.write("\e[" & $gBG & 'm')

proc isatty*(f: TFile): bool =
  ## returns true if `f` is associated with a terminal device.
  when defined(posix):
    proc isatty(fildes: TFileHandle): cint {.
      importc: "isatty", header: "<unistd.h>".}
  else:
    proc isatty(fildes: TFileHandle): cint {.
      importc: "_isatty", header: "<io.h>".}

  result = isatty(fileHandle(f)) != 0'i32

proc styledEchoProcessArg(s: string)               = write stdout, s
proc styledEchoProcessArg(style: TStyle)           = setStyle({style})
proc styledEchoProcessArg(style: set[TStyle])      = setStyle style
proc styledEchoProcessArg(color: TForegroundColor) = setForeGroundColor color
proc styledEchoProcessArg(color: TBackgroundColor) = setBackGroundColor color

macro styledEcho*(m: varargs[expr]): stmt =
  ## to be documented.
  let m = callsite()
  result = newNimNode(nnkStmtList)

  for i in countup(1, m.len - 1):
    result.add(newCall(bindSym"styledEchoProcessArg", m[i]))

  result.add(newCall(bindSym"write", bindSym"stdout", newStrLitNode("\n")))
  result.add(newCall(bindSym"resetAttributes"))

when isMainModule:
  system.addQuitProc(resetAttributes)
  write(stdout, "never mind")
  eraseLine()
  #setCursorPos(2, 2)
  writeStyled("styled text ", {styleBright, styleBlink, styleUnderscore})
  setBackGroundColor(bgCyan, true)
  setForeGroundColor(fgBlue)
  writeln(stdout, "ordinary text")

  styledEcho("styled text ", {styleBright, styleBlink, styleUnderscore})
