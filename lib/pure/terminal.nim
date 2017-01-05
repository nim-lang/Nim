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
## Similarly, if you hide the cursor, make sure to unhide it with
## ``showCursor`` before quitting.

import macros

when defined(windows):
  import winlean, os

  const
    DUPLICATE_SAME_ACCESS = 2
    FOREGROUND_BLUE = 1
    FOREGROUND_GREEN = 2
    FOREGROUND_RED = 4
    FOREGROUND_INTENSITY = 8
    BACKGROUND_BLUE = 16
    BACKGROUND_GREEN = 32
    BACKGROUND_RED = 64
    BACKGROUND_INTENSITY = 128
    FOREGROUND_RGB = FOREGROUND_RED or FOREGROUND_GREEN or FOREGROUND_BLUE
    BACKGROUND_RGB = BACKGROUND_RED or BACKGROUND_GREEN or BACKGROUND_BLUE

  type
    SHORT = int16
    COORD = object
      X: SHORT
      Y: SHORT

    SMALL_RECT = object
      Left: SHORT
      Top: SHORT
      Right: SHORT
      Bottom: SHORT

    CONSOLE_SCREEN_BUFFER_INFO = object
      dwSize: COORD
      dwCursorPosition: COORD
      wAttributes: int16
      srWindow: SMALL_RECT
      dwMaximumWindowSize: COORD

    CONSOLE_CURSOR_INFO = object
      dwSize: DWORD
      bVisible: WINBOOL

  proc duplicateHandle(hSourceProcessHandle: HANDLE, hSourceHandle: HANDLE,
                       hTargetProcessHandle: HANDLE, lpTargetHandle: ptr HANDLE,
                       dwDesiredAccess: DWORD, bInheritHandle: WINBOOL,
                       dwOptions: DWORD): WINBOOL{.stdcall, dynlib: "kernel32",
      importc: "DuplicateHandle".}
  proc getCurrentProcess(): HANDLE{.stdcall, dynlib: "kernel32",
                                     importc: "GetCurrentProcess".}
  proc getConsoleScreenBufferInfo(hConsoleOutput: HANDLE,
    lpConsoleScreenBufferInfo: ptr CONSOLE_SCREEN_BUFFER_INFO): WINBOOL{.stdcall,
    dynlib: "kernel32", importc: "GetConsoleScreenBufferInfo".}

  proc getConsoleCursorInfo(hConsoleOutput: HANDLE,
      lpConsoleCursorInfo: ptr CONSOLE_CURSOR_INFO): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "GetConsoleCursorInfo".}

  proc setConsoleCursorInfo(hConsoleOutput: HANDLE,
      lpConsoleCursorInfo: ptr CONSOLE_CURSOR_INFO): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "SetConsoleCursorInfo".}

  proc terminalWidthIoctl*(handles: openArray[Handle]): int =
    var csbi: CONSOLE_SCREEN_BUFFER_INFO
    for h in handles:
      if getConsoleScreenBufferInfo(h, addr csbi) != 0:
        return int(csbi.srWindow.Right - csbi.srWindow.Left + 1)
    return 0

  proc terminalHeightIoctl*(handles: openArray[Handle]): int =
    var csbi: CONSOLE_SCREEN_BUFFER_INFO
    for h in handles:
      if getConsoleScreenBufferInfo(h, addr csbi) != 0:
        return int(csbi.srWindow.Bottom - csbi.srWindow.Top + 1)
    return 0

  proc terminalWidth*(): int =
    var w: int = 0
    w = terminalWidthIoctl([ getStdHandle(STD_INPUT_HANDLE),
                             getStdHandle(STD_OUTPUT_HANDLE),
                             getStdHandle(STD_ERROR_HANDLE) ] )
    if w > 0: return w
    return 80

  proc terminalHeight*(): int =
    var h: int = 0
    h = terminalHeightIoctl([ getStdHandle(STD_INPUT_HANDLE),
                              getStdHandle(STD_OUTPUT_HANDLE),
                              getStdHandle(STD_ERROR_HANDLE) ] )
    if h > 0: return h
    return 0

  proc setConsoleCursorPosition(hConsoleOutput: HANDLE,
                                dwCursorPosition: COORD): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "SetConsoleCursorPosition".}

  proc fillConsoleOutputCharacter(hConsoleOutput: Handle, cCharacter: char,
                                  nLength: DWORD, dwWriteCoord: Coord,
                                  lpNumberOfCharsWritten: ptr DWORD): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "FillConsoleOutputCharacterA".}

  proc fillConsoleOutputAttribute(hConsoleOutput: HANDLE, wAttribute: int16,
                                  nLength: DWORD, dwWriteCoord: COORD,
                                  lpNumberOfAttrsWritten: ptr DWORD): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "FillConsoleOutputAttribute".}

  proc setConsoleTextAttribute(hConsoleOutput: HANDLE,
                               wAttributes: int16): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "SetConsoleTextAttribute".}

  var
    hStdout: Handle # = createFile("CONOUT$", GENERIC_WRITE, 0, nil,
                    #              OPEN_ALWAYS, 0, 0)
    hStderr: Handle

  block:
    var hStdoutTemp = getStdHandle(STD_OUTPUT_HANDLE)
    if duplicateHandle(getCurrentProcess(), hStdoutTemp, getCurrentProcess(),
                       addr(hStdout), 0, 1, DUPLICATE_SAME_ACCESS) == 0:
      when defined(consoleapp):
        raiseOSError(osLastError())
    var hStderrTemp = getStdHandle(STD_ERROR_HANDLE)
    if duplicateHandle(getCurrentProcess(), hStderrTemp, getCurrentProcess(),
                       addr(hStderr), 0, 1, DUPLICATE_SAME_ACCESS) == 0:
      when defined(consoleapp):
        raiseOSError(osLastError())

  proc getCursorPos(h: Handle): tuple [x,y: int] =
    var c: CONSOLESCREENBUFFERINFO
    if getConsoleScreenBufferInfo(h, addr(c)) == 0:
      raiseOSError(osLastError())
    return (int(c.dwCursorPosition.X), int(c.dwCursorPosition.Y))

  proc setCursorPos(h: Handle, x, y: int) =
    var c: COORD
    c.X = int16(x)
    c.Y = int16(y)
    if setConsoleCursorPosition(h, c) == 0:
      raiseOSError(osLastError())

  proc getAttributes(h: Handle): int16 =
    var c: CONSOLESCREENBUFFERINFO
    # workaround Windows bugs: try several times
    if getConsoleScreenBufferInfo(h, addr(c)) != 0:
      return c.wAttributes
    return 0x70'i16 # ERROR: return white background, black text

  var
    oldStdoutAttr = getAttributes(hStdout)
    oldStderrAttr = getAttributes(hStderr)

  template conHandle(f: File): Handle =
    if f == stderr: hStderr else: hStdout

else:
  import termios, posix, os, parseutils

  proc setRaw(fd: FileHandle, time: cint = TCSAFLUSH) =
    var mode: Termios
    discard fd.tcgetattr(addr mode)
    mode.c_iflag = mode.c_iflag and not Cflag(BRKINT or ICRNL or INPCK or
      ISTRIP or IXON)
    mode.c_oflag = mode.c_oflag and not Cflag(OPOST)
    mode.c_cflag = (mode.c_cflag and not Cflag(CSIZE or PARENB)) or CS8
    mode.c_lflag = mode.c_lflag and not Cflag(ECHO or ICANON or IEXTEN or ISIG)
    mode.c_cc[VMIN] = 1.cuchar
    mode.c_cc[VTIME] = 0.cuchar
    discard fd.tcsetattr(time, addr mode)

  proc terminalWidthIoctl*(fds: openArray[int]): int =
    ## Returns terminal width from first fd that supports the ioctl.

    var win: IOctl_WinSize
    for fd in fds:
      if ioctl(cint(fd), TIOCGWINSZ, addr win) != -1:
        return int(win.ws_col)
    return 0

  proc terminalHeightIoctl*(fds: openArray[int]): int =
    ## Returns terminal height from first fd that supports the ioctl.

    var win: IOctl_WinSize
    for fd in fds:
      if ioctl(cint(fd), TIOCGWINSZ, addr win) != -1:
        return int(win.ws_row)
    return 0

  var L_ctermid{.importc, header: "<stdio.h>".}: cint

  proc terminalWidth*(): int =
    ## Returns some reasonable terminal width from either standard file
    ## descriptors, controlling terminal, environment variables or tradition.

    var w = terminalWidthIoctl([0, 1, 2])   #Try standard file descriptors
    if w > 0: return w
    var cterm = newString(L_ctermid)        #Try controlling tty
    var fd = open(ctermid(cstring(cterm)), O_RDONLY)
    if fd != -1:
      w = terminalWidthIoctl([ int(fd) ])
    discard close(fd)
    if w > 0: return w
    var s = getEnv("COLUMNS")               #Try standard env var
    if len(s) > 0 and parseInt(string(s), w) > 0 and w > 0:
      return w
    return 80                               #Finally default to venerable value

  proc terminalHeight*(): int =
    ## Returns some reasonable terminal height from either standard file
    ## descriptors, controlling terminal, environment variables or tradition.
    ## Zero is returned if the height could not be determined.

    var h = terminalHeightIoctl([0, 1, 2])  # Try standard file descriptors
    if h > 0: return h
    var cterm = newString(L_ctermid)        # Try controlling tty
    var fd = open(ctermid(cstring(cterm)), O_RDONLY)
    if fd != -1:
      h = terminalHeightIoctl([ int(fd) ])
    discard close(fd)
    if h > 0: return h
    var s = getEnv("LINES")                 # Try standard env var
    if len(s) > 0 and parseInt(string(s), h) > 0 and h > 0:
      return h
    return 0                                # Could not determine height

proc terminalSize*(): tuple[w, h: int] =
  ## Returns the terminal width and height as a tuple. Internally calls
  ## `terminalWidth` and `terminalHeight`, so the same assumptions apply.
  result = (terminalWidth(), terminalHeight())

when defined(windows):
  proc setCursorVisibility(f: File, visible: bool) =
    var ccsi: CONSOLE_CURSOR_INFO
    let h = conHandle(f)
    if getConsoleCursorInfo(h, addr(ccsi)) == 0:
      raiseOSError(osLastError())
    ccsi.bVisible = if visible: 1 else: 0
    if setConsoleCursorInfo(h, addr(ccsi)) == 0:
      raiseOSError(osLastError())

proc hideCursor*(f: File) =
  ## Hides the cursor.
  when defined(windows):
    setCursorVisibility(f, false)
  else:
    f.write("\e[?25l")

proc showCursor*(f: File) =
  ## Shows the cursor.
  when defined(windows):
    setCursorVisibility(f, true)
  else:
    f.write("\e[?25h")

proc setCursorPos*(f: File, x, y: int) =
  ## Sets the terminal's cursor to the (x,y) position.
  ## (0,0) is the upper left of the screen.
  when defined(windows):
    let h = conHandle(f)
    setCursorPos(h, x, y)
  else:
    f.write("\e[" & $y & ';' & $x & 'f')

proc setCursorXPos*(f: File, x: int) =
  ## Sets the terminal's cursor to the x position.
  ## The y position is not changed.
  when defined(windows):
    let h = conHandle(f)
    var scrbuf: CONSOLESCREENBUFFERINFO
    if getConsoleScreenBufferInfo(h, addr(scrbuf)) == 0:
      raiseOSError(osLastError())
    var origin = scrbuf.dwCursorPosition
    origin.X = int16(x)
    if setConsoleCursorPosition(h, origin) == 0:
      raiseOSError(osLastError())
  else:
    f.write("\e[" & $x & 'G')

when defined(windows):
  proc setCursorYPos*(f: File, y: int) =
    ## Sets the terminal's cursor to the y position.
    ## The x position is not changed.
    ## **Warning**: This is not supported on UNIX!
    when defined(windows):
      let h = conHandle(f)
      var scrbuf: CONSOLESCREENBUFFERINFO
      if getConsoleScreenBufferInfo(h, addr(scrbuf)) == 0:
        raiseOSError(osLastError())
      var origin = scrbuf.dwCursorPosition
      origin.Y = int16(y)
      if setConsoleCursorPosition(h, origin) == 0:
        raiseOSError(osLastError())
    else:
      discard

proc cursorUp*(f: File, count=1) =
  ## Moves the cursor up by `count` rows.
  when defined(windows):
    let h = conHandle(f)
    var p = getCursorPos(h)
    dec(p.y, count)
    setCursorPos(h, p.x, p.y)
  else:
    f.write("\e[" & $count & 'A')

proc cursorDown*(f: File, count=1) =
  ## Moves the cursor down by `count` rows.
  when defined(windows):
    let h = conHandle(f)
    var p = getCursorPos(h)
    inc(p.y, count)
    setCursorPos(h, p.x, p.y)
  else:
    f.write("\e[" & $count & 'B')

proc cursorForward*(f: File, count=1) =
  ## Moves the cursor forward by `count` columns.
  when defined(windows):
    let h = conHandle(f)
    var p = getCursorPos(h)
    inc(p.x, count)
    setCursorPos(h, p.x, p.y)
  else:
    f.write("\e[" & $count & 'C')

proc cursorBackward*(f: File, count=1) =
  ## Moves the cursor backward by `count` columns.
  when defined(windows):
    let h = conHandle(f)
    var p = getCursorPos(h)
    dec(p.x, count)
    setCursorPos(h, p.x, p.y)
  else:
    f.write("\e[" & $count & 'D')

when true:
  discard
else:
  proc eraseLineEnd*(f: File) =
    ## Erases from the current cursor position to the end of the current line.
    when defined(windows):
      discard
    else:
      f.write("\e[K")

  proc eraseLineStart*(f: File) =
    ## Erases from the current cursor position to the start of the current line.
    when defined(windows):
      discard
    else:
      f.write("\e[1K")

  proc eraseDown*(f: File) =
    ## Erases the screen from the current line down to the bottom of the screen.
    when defined(windows):
      discard
    else:
      f.write("\e[J")

  proc eraseUp*(f: File) =
    ## Erases the screen from the current line up to the top of the screen.
    when defined(windows):
      discard
    else:
      f.write("\e[1J")

proc eraseLine*(f: File) =
  ## Erases the entire current line.
  when defined(windows):
    let h = conHandle(f)
    var scrbuf: CONSOLESCREENBUFFERINFO
    var numwrote: DWORD
    if getConsoleScreenBufferInfo(h, addr(scrbuf)) == 0:
      raiseOSError(osLastError())
    var origin = scrbuf.dwCursorPosition
    origin.X = 0'i16
    if setConsoleCursorPosition(h, origin) == 0:
      raiseOSError(osLastError())
    var ht = scrbuf.dwSize.Y - origin.Y
    var wt = scrbuf.dwSize.X - origin.X
    if fillConsoleOutputCharacter(h, ' ', ht*wt,
                                  origin, addr(numwrote)) == 0:
      raiseOSError(osLastError())
    if fillConsoleOutputAttribute(h, scrbuf.wAttributes, ht * wt,
                                  scrbuf.dwCursorPosition, addr(numwrote)) == 0:
      raiseOSError(osLastError())
  else:
    f.write("\e[2K")
    setCursorXPos(f, 0)

proc eraseScreen*(f: File) =
  ## Erases the screen with the background colour and moves the cursor to home.
  when defined(windows):
    let h = conHandle(f)
    var scrbuf: CONSOLESCREENBUFFERINFO
    var numwrote: DWORD
    var origin: COORD # is inititalized to 0, 0

    if getConsoleScreenBufferInfo(h, addr(scrbuf)) == 0:
      raiseOSError(osLastError())
    let numChars = int32(scrbuf.dwSize.X)*int32(scrbuf.dwSize.Y)

    if fillConsoleOutputCharacter(h, ' ', numChars,
                                  origin, addr(numwrote)) == 0:
      raiseOSError(osLastError())
    if fillConsoleOutputAttribute(h, scrbuf.wAttributes, numChars,
                                  origin, addr(numwrote)) == 0:
      raiseOSError(osLastError())
    setCursorXPos(f, 0)
  else:
    f.write("\e[2J")

proc resetAttributes*(f: File) =
  ## Resets all attributes.
  when defined(windows):
    if f == stderr:
      discard setConsoleTextAttribute(hStderr, oldStderrAttr)
    else:
      discard setConsoleTextAttribute(hStdout, oldStdoutAttr)
  else:
    f.write("\e[0m")

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

proc setStyle*(f: File, style: set[Style]) =
  ## Sets the terminal style.
  when defined(windows):
    let h = conHandle(f)
    var old = getAttributes(h) and (FOREGROUND_RGB or BACKGROUND_RGB)
    var a = 0'i16
    if styleBright in style: a = a or int16(FOREGROUND_INTENSITY)
    if styleBlink in style: a = a or int16(BACKGROUND_INTENSITY)
    if styleReverse in style: a = a or 0x4000'i16 # COMMON_LVB_REVERSE_VIDEO
    if styleUnderscore in style: a = a or 0x8000'i16 # COMMON_LVB_UNDERSCORE
    discard setConsoleTextAttribute(h, old or a)
  else:
    for s in items(style):
      f.write("\e[" & $ord(s) & 'm')

proc writeStyled*(txt: string, style: set[Style] = {styleBright}) =
  ## Writes the text `txt` in a given `style` to stdout.
  when defined(windows):
    var old = getAttributes(hStdout)
    stdout.setStyle(style)
    stdout.write(txt)
    discard setConsoleTextAttribute(hStdout, old)
  else:
    stdout.setStyle(style)
    stdout.write(txt)
    stdout.resetAttributes()
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

proc setForegroundColor*(f: File, fg: ForegroundColor, bright=false) =
  ## Sets the terminal's foreground color.
  when defined(windows):
    let h = conHandle(f)
    var old = getAttributes(h) and not FOREGROUND_RGB
    if bright:
      old = old or FOREGROUND_INTENSITY
    const lookup: array[ForegroundColor, int] = [
      0,
      (FOREGROUND_RED),
      (FOREGROUND_GREEN),
      (FOREGROUND_RED or FOREGROUND_GREEN),
      (FOREGROUND_BLUE),
      (FOREGROUND_RED or FOREGROUND_BLUE),
      (FOREGROUND_BLUE or FOREGROUND_GREEN),
      (FOREGROUND_BLUE or FOREGROUND_GREEN or FOREGROUND_RED)]
    discard setConsoleTextAttribute(h, toU16(old or lookup[fg]))
  else:
    gFG = ord(fg)
    if bright: inc(gFG, 60)
    f.write("\e[" & $gFG & 'm')

proc setBackgroundColor*(f: File, bg: BackgroundColor, bright=false) =
  ## Sets the terminal's background color.
  when defined(windows):
    let h = conHandle(f)
    var old = getAttributes(h) and not BACKGROUND_RGB
    if bright:
      old = old or BACKGROUND_INTENSITY
    const lookup: array[BackgroundColor, int] = [
      0,
      (BACKGROUND_RED),
      (BACKGROUND_GREEN),
      (BACKGROUND_RED or BACKGROUND_GREEN),
      (BACKGROUND_BLUE),
      (BACKGROUND_RED or BACKGROUND_BLUE),
      (BACKGROUND_BLUE or BACKGROUND_GREEN),
      (BACKGROUND_BLUE or BACKGROUND_GREEN or BACKGROUND_RED)]
    discard setConsoleTextAttribute(h, toU16(old or lookup[bg]))
  else:
    gBG = ord(bg)
    if bright: inc(gBG, 60)
    f.write("\e[" & $gBG & 'm')

proc isatty*(f: File): bool =
  ## Returns true if `f` is associated with a terminal device.
  when defined(posix):
    proc isatty(fildes: FileHandle): cint {.
      importc: "isatty", header: "<unistd.h>".}
  else:
    proc isatty(fildes: FileHandle): cint {.
      importc: "_isatty", header: "<io.h>".}

  result = isatty(getFileHandle(f)) != 0'i32

type
  TerminalCmd* = enum  ## commands that can be expressed as arguments
    resetStyle         ## reset attributes

template styledEchoProcessArg(f: File, s: string) = write f, s
template styledEchoProcessArg(f: File, style: Style) = setStyle(f, {style})
template styledEchoProcessArg(f: File, style: set[Style]) = setStyle f, style
template styledEchoProcessArg(f: File, color: ForegroundColor) =
  setForegroundColor f, color
template styledEchoProcessArg(f: File, color: BackgroundColor) =
  setBackgroundColor f, color
template styledEchoProcessArg(f: File, cmd: TerminalCmd) =
  when cmd == resetStyle:
    resetAttributes(f)

macro styledWriteLine*(f: File, m: varargs[expr]): stmt =
  ## Similar to ``writeLine``, but treating terminal style arguments specially.
  ## When some argument is ``Style``, ``set[Style]``, ``ForegroundColor``,
  ## ``BackgroundColor`` or ``TerminalCmd`` then it is not sent directly to
  ## ``f``, but instead corresponding terminal style proc is called.
  ##
  ## Example:
  ##
  ## .. code-block:: nim
  ##
  ##   proc error(msg: string) =
  ##     styleWriteLine(stderr, fgRed, "Error: ", resetStyle, msg)
  ##
  let m = callsite()
  var reset = false
  result = newNimNode(nnkStmtList)

  for i in countup(2, m.len - 1):
    let item = m[i]
    case item.kind
    of nnkStrLit..nnkTripleStrLit:
      if i == m.len - 1:
        # optimize if string literal is last, just call writeLine
        result.add(newCall(bindSym"writeLine", f, item))
        if reset: result.add(newCall(bindSym"resetAttributes", f))
        return
      else:
        # if it is string literal just call write, do not enable reset
        result.add(newCall(bindSym"write", f, item))
    else:
      result.add(newCall(bindSym"styledEchoProcessArg", f, item))
      reset = true

  result.add(newCall(bindSym"write", f, newStrLitNode("\n")))
  if reset: result.add(newCall(bindSym"resetAttributes", f))

macro callStyledEcho(args: varargs[expr]): stmt =
  result = newCall(bindSym"styledWriteLine")
  result.add(bindSym"stdout")
  for arg in children(args[0][1]):
    result.add(arg)

template styledEcho*(args: varargs[expr]): expr =
  ## Echoes styles arguments to stdout using ``styledWriteLine``.
  callStyledEcho(args)

proc getch*(): char =
  ## Read a single character from the terminal, blocking until it is entered.
  ## The character is not printed to the terminal.
  when defined(windows):
    let fd = getStdHandle(STD_INPUT_HANDLE)
    var keyEvent = KEY_EVENT_RECORD()
    var numRead: cint 
    while true:
      # Block until character is entered
      doAssert(waitForSingleObject(fd, INFINITE) == WAIT_OBJECT_0)
      doAssert(readConsoleInput(fd, addr(keyEvent), 1, addr(numRead)) != 0)
      if numRead == 0 or keyEvent.eventType != 1 or keyEvent.bKeyDown == 0:
        continue
      return char(keyEvent.uChar)
  else:
    let fd = getFileHandle(stdin)
    var oldMode: Termios
    discard fd.tcgetattr(addr oldMode)
    fd.setRaw()
    result = stdin.readChar()
    discard fd.tcsetattr(TCSADRAIN, addr oldMode)

# Wrappers assuming output to stdout:
template hideCursor*() = hideCursor(stdout)
template showCursor*() = showCursor(stdout)
template setCursorPos*(x, y: int) = setCursorPos(stdout, x, y)
template setCursorXPos*(x: int)   = setCursorXPos(stdout, x)
when defined(windows):
  template setCursorYPos(x: int)  = setCursorYPos(stdout, x)
template cursorUp*(count=1)       = cursorUp(stdout, f)
template cursorDown*(count=1)     = cursorDown(stdout, f)
template cursorForward*(count=1)  = cursorForward(stdout, f)
template cursorBackward*(count=1) = cursorBackward(stdout, f)
template eraseLine*()             = eraseLine(stdout)
template eraseScreen*()           = eraseScreen(stdout)
template setStyle*(style: set[Style]) =
  setStyle(stdout, style)
template setForegroundColor*(fg: ForegroundColor, bright=false) =
  setForegroundColor(stdout, fg, bright)
template setBackgroundColor*(bg: BackgroundColor, bright=false) =
  setBackgroundColor(stdout, bg, bright)
proc resetAttributes*() {.noconv.} =
  ## Resets all attributes on stdout.
  ## It is advisable to register this as a quit proc with
  ## ``system.addQuitProc(resetAttributes)``.
  resetAttributes(stdout)

when not defined(testing) and isMainModule:
  #system.addQuitProc(resetAttributes)
  write(stdout, "never mind")
  stdout.eraseLine()
  stdout.styledWriteLine("styled text ", {styleBright, styleBlink, styleUnderscore})
  stdout.setBackGroundColor(bgCyan, true)
  stdout.setForeGroundColor(fgBlue)
  stdout.writeLine("ordinary text")
  stdout.resetAttributes()
