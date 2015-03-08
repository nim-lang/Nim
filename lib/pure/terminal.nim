#
#
#            Nim's Runtime Library
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
      raiseOSError(osLastError())

  proc getCursorPos(): tuple [x,y: int] =
    var c: TCONSOLESCREENBUFFERINFO
    if GetConsoleScreenBufferInfo(conHandle, addr(c)) == 0:
      raiseOSError(osLastError())
    return (int(c.dwCursorPosition.X), int(c.dwCursorPosition.Y))

  proc getAttributes(): int16 =
    var c: TCONSOLESCREENBUFFERINFO
    # workaround Windows bugs: try several times
    if GetConsoleScreenBufferInfo(conHandle, addr(c)) != 0:
      return c.wAttributes
    return 0x70'i16 # ERROR: return white background, black text

  var
    oldAttr = getAttributes()

else:
  import termios, unsigned

  proc setRaw(fd: FileHandle, time: cint = TCSAFLUSH) =
    var mode: Termios
    discard fd.tcgetattr(addr mode)
    mode.iflag = mode.iflag and not Tcflag(BRKINT or ICRNL or INPCK or ISTRIP or IXON)
    mode.oflag = mode.oflag and not Tcflag(OPOST)
    mode.cflag = (mode.cflag and not Tcflag(CSIZE or PARENB)) or CS8
    mode.lflag = mode.lflag and not Tcflag(ECHO or ICANON or IEXTEN or ISIG)
    mode.cc[VMIN] = 1.cuchar
    mode.cc[VTIME] = 0.cuchar
    discard fd.tcsetattr(time, addr mode)

proc setCursorPos*(x, y: int) =
  ## sets the terminal's cursor to the (x,y) position. (0,0) is the
  ## upper left of the screen.
  when defined(windows):
    var c: TCOORD
    c.X = int16(x)
    c.Y = int16(y)
    if SetConsoleCursorPosition(conHandle, c) == 0: raiseOSError(osLastError())
  else:
    stdout.write("\e[" & $y & ';' & $x & 'f')

proc setCursorXPos*(x: int) =
  ## sets the terminal's cursor to the x position. The y position is
  ## not changed.
  when defined(windows):
    var scrbuf: TCONSOLESCREENBUFFERINFO
    var hStdout = conHandle
    if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0:
      raiseOSError(osLastError())
    var origin = scrbuf.dwCursorPosition
    origin.X = int16(x)
    if SetConsoleCursorPosition(conHandle, origin) == 0:
      raiseOSError(osLastError())
  else:
    stdout.write("\e[" & $x & 'G')

when defined(windows):
  proc setCursorYPos*(y: int) =
    ## sets the terminal's cursor to the y position. The x position is
    ## not changed. **Warning**: This is not supported on UNIX!
    when defined(windows):
      var scrbuf: TCONSOLESCREENBUFFERINFO
      var hStdout = conHandle
      if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0:
        raiseOSError(osLastError())
      var origin = scrbuf.dwCursorPosition
      origin.Y = int16(y)
      if SetConsoleCursorPosition(conHandle, origin) == 0:
        raiseOSError(osLastError())
    else:
      discard

proc cursorUp*(count=1) =
  ## Moves the cursor up by `count` rows.
  when defined(windows):
    var p = getCursorPos()
    dec(p.y, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'A')

proc cursorDown*(count=1) =
  ## Moves the cursor down by `count` rows.
  when defined(windows):
    var p = getCursorPos()
    inc(p.y, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'B')

proc cursorForward*(count=1) =
  ## Moves the cursor forward by `count` columns.
  when defined(windows):
    var p = getCursorPos()
    inc(p.x, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'C')

proc cursorBackward*(count=1) =
  ## Moves the cursor backward by `count` columns.
  when defined(windows):
    var p = getCursorPos()
    dec(p.x, count)
    setCursorPos(p.x, p.y)
  else:
    stdout.write("\e[" & $count & 'D')

when true:
  discard
else:
  proc eraseLineEnd* =
    ## Erases from the current cursor position to the end of the current line.
    when defined(windows):
      discard
    else:
      stdout.write("\e[K")

  proc eraseLineStart* =
    ## Erases from the current cursor position to the start of the current line.
    when defined(windows):
      discard
    else:
      stdout.write("\e[1K")

  proc eraseDown* =
    ## Erases the screen from the current line down to the bottom of the screen.
    when defined(windows):
      discard
    else:
      stdout.write("\e[J")

  proc eraseUp* =
    ## Erases the screen from the current line up to the top of the screen.
    when defined(windows):
      discard
    else:
      stdout.write("\e[1J")

proc eraseLine* =
  ## Erases the entire current line.
  when defined(windows):
    var scrbuf: TCONSOLESCREENBUFFERINFO
    var numwrote: DWORD
    var hStdout = conHandle
    if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0:
      raiseOSError(osLastError())
    var origin = scrbuf.dwCursorPosition
    origin.X = 0'i16
    if SetConsoleCursorPosition(conHandle, origin) == 0:
      raiseOSError(osLastError())
    var ht = scrbuf.dwSize.Y - origin.Y
    var wt = scrbuf.dwSize.X - origin.X
    if FillConsoleOutputCharacter(hStdout,' ', ht*wt,
                                  origin, addr(numwrote)) == 0:
      raiseOSError(osLastError())
    if FillConsoleOutputAttribute(hStdout, scrbuf.wAttributes, ht * wt,
                                  scrbuf.dwCursorPosition, addr(numwrote)) == 0:
      raiseOSError(osLastError())
  else:
    stdout.write("\e[2K")
    setCursorXPos(0)

proc eraseScreen* =
  ## Erases the screen with the background colour and moves the cursor to home.
  when defined(windows):
    var scrbuf: TCONSOLESCREENBUFFERINFO
    var numwrote: DWORD
    var origin: TCOORD # is inititalized to 0, 0
    var hStdout = conHandle

    if GetConsoleScreenBufferInfo(hStdout, addr(scrbuf)) == 0:
      raiseOSError(osLastError())
    let numChars = int32(scrbuf.dwSize.X)*int32(scrbuf.dwSize.Y)

    if FillConsoleOutputCharacter(hStdout, ' ', numChars,
                                  origin, addr(numwrote)) == 0:
      raiseOSError(osLastError())
    if FillConsoleOutputAttribute(hStdout, scrbuf.wAttributes, numChars,
                                  origin, addr(numwrote)) == 0:
      raiseOSError(osLastError())
    setCursorXPos(0)
  else:
    stdout.write("\e[2J")

proc resetAttributes* {.noconv.} =
  ## resets all attributes; it is advisable to register this as a quit proc
  ## with ``system.addQuitProc(resetAttributes)``.
  when defined(windows):
    discard SetConsoleTextAttribute(conHandle, oldAttr)
  else:
    stdout.write("\e[0m")

type
  Style* = enum         ## different styles for text output
    styleBright = 1,     ## bright text
    styleDim,            ## dim text
    styleUnknown,        ## unknown
    styleUnderscore = 4, ## underscored text
    styleBlink,          ## blinking/bold text
    styleReverse = 7,    ## unknown
    styleHidden          ## hidden text

{.deprecated: [TStyle: Style].}

when not defined(windows):
  var
    # XXX: These better be thread-local
    gFG = 0
    gBG = 0

proc setStyle*(style: set[Style]) =
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

proc writeStyled*(txt: string, style: set[Style] = {styleBright}) =
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
  ForegroundColor* = enum  ## terminal's foreground colors
    fgBlack = 30,          ## black
    fgRed,                 ## red
    fgGreen,               ## green
    fgYellow,              ## yellow
    fgBlue,                ## blue
    fgMagenta,             ## magenta
    fgCyan,                ## cyan
    fgWhite                ## white

  BackgroundColor* = enum  ## terminal's background colors
    bgBlack = 40,          ## black
    bgRed,                 ## red
    bgGreen,               ## green
    bgYellow,              ## yellow
    bgBlue,                ## blue
    bgMagenta,             ## magenta
    bgCyan,                ## cyan
    bgWhite                ## white

{.deprecated: [TForegroundColor: ForegroundColor,
               TBackgroundColor: BackgroundColor].}

proc setForegroundColor*(fg: ForegroundColor, bright=false) =
  ## sets the terminal's foreground color
  when defined(windows):
    var old = getAttributes() and not 0x0007
    if bright:
      old = old or FOREGROUND_INTENSITY
    const lookup: array [ForegroundColor, int] = [
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

proc setBackgroundColor*(bg: BackgroundColor, bright=false) =
  ## sets the terminal's background color
  when defined(windows):
    var old = getAttributes() and not 0x0070
    if bright:
      old = old or BACKGROUND_INTENSITY
    const lookup: array [BackgroundColor, int] = [
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

proc isatty*(f: File): bool =
  ## returns true if `f` is associated with a terminal device.
  when defined(posix):
    proc isatty(fildes: FileHandle): cint {.
      importc: "isatty", header: "<unistd.h>".}
  else:
    proc isatty(fildes: FileHandle): cint {.
      importc: "_isatty", header: "<io.h>".}

  result = isatty(getFileHandle(f)) != 0'i32

proc styledEchoProcessArg(s: string) = write stdout, s
proc styledEchoProcessArg(style: Style) = setStyle({style})
proc styledEchoProcessArg(style: set[Style]) = setStyle style
proc styledEchoProcessArg(color: ForegroundColor) = setForegroundColor color
proc styledEchoProcessArg(color: BackgroundColor) = setBackgroundColor color

macro styledEcho*(m: varargs[expr]): stmt =
  ## to be documented.
  let m = callsite()
  result = newNimNode(nnkStmtList)

  for i in countup(1, m.len - 1):
    result.add(newCall(bindSym"styledEchoProcessArg", m[i]))

  result.add(newCall(bindSym"write", bindSym"stdout", newStrLitNode("\n")))
  result.add(newCall(bindSym"resetAttributes"))

when not defined(windows):
  proc getch*(): char =
    ## Read a single character from the terminal, blocking until it is entered.
    ## The character is not printed to the terminal. This is not available for
    ## Windows.
    let fd = getFileHandle(stdin)
    var oldMode: Termios
    discard fd.tcgetattr(addr oldMode)
    fd.setRaw()
    result = stdin.readChar()
    discard fd.tcsetattr(TCSADRAIN, addr oldMode)

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

