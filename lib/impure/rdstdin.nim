#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains code for reading from `stdin`:idx:. On UNIX the GNU
## readline library is wrapped and set up to provide default key bindings
## (e.g. you can navigate with the arrow keys). On Windows ``system.readLine``
## is used. This suffices because Windows' console already provides the
## wanted functionality.

{.deadCodeElim: on.}

when defined(Windows):
  proc readLineFromStdin*(prompt: string): TaintedString {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    ## Reads a line from stdin.
    stdout.write(prompt)
    result = readLine(stdin)

  proc readLineFromStdin*(prompt: string, line: var TaintedString): bool {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    ## Reads a `line` from stdin. `line` must not be
    ## ``nil``! May throw an IO exception.
    ## A line of text may be delimited by ``CR``, ``LF`` or
    ## ``CRLF``. The newline character(s) are not part of the returned string.
    ## Returns ``false`` if the end of the file has been reached, ``true``
    ## otherwise. If ``false`` is returned `line` contains no new data.
    stdout.write(prompt)
    result = readLine(stdin, line)

  import winlean

  const
    VK_SHIFT* = 16
    VK_CONTROL* = 17
    VK_MENU* = 18
    KEY_EVENT* = 1

  type
    KEY_EVENT_RECORD = object
      bKeyDown: WinBool
      wRepeatCount: uint16
      wVirtualKeyCode: uint16
      wVirtualScanCode: uint16
      unicodeChar: uint16
      dwControlKeyState: uint32
    INPUT_RECORD = object
      eventType*: int16
      reserved*: int16
      event*: KEY_EVENT_RECORD
      safetyBuffer: array[0..5, DWORD]

  proc readConsoleInputW*(hConsoleInput: THANDLE, lpBuffer: var INPUTRECORD,
                          nLength: uint32,
                          lpNumberOfEventsRead: var uint32): WINBOOL{.
      stdcall, dynlib: "kernel32", importc: "ReadConsoleInputW".}

  proc getch(): uint16 =
    let hStdin = getStdHandle(STD_INPUT_HANDLE)
    var
      irInputRecord: INPUT_RECORD
      dwEventsRead: uint32

    while readConsoleInputW(hStdin, irInputRecord, 1, dwEventsRead) != 0:
      if irInputRecord.eventType == KEY_EVENT and
          irInputRecord.event.wVirtualKeyCode notin {VK_SHIFT, VK_MENU, VK_CONTROL}:
         result = irInputRecord.event.unicodeChar
         discard readConsoleInputW(hStdin, irInputRecord, 1, dwEventsRead)
         return result

  from unicode import toUTF8, Rune, runeLenAt

  proc readPasswordFromStdin*(prompt: string, password: var TaintedString):
                              bool {.tags: [ReadIOEffect, WriteIOEffect].} =
    ## Reads a `password` from stdin without printing it. `password` must not
    ## be ``nil``! Returns ``false`` if the end of the file has been reached,
    ## ``true`` otherwise.
    password.setLen(0)
    stdout.write(prompt)
    while true:
      let c = getch()
      case c.char
      of '\r', chr(0xA):
        break
      of '\b':
        # ensure we delete the whole UTF-8 character:
        var i = 0
        var x = 1
        while i < password.len:
          x = runeLenAt(password, i)
          inc i, x
        password.setLen(password.len - x)
      else:
        password.add(toUTF8(c.Rune))
    stdout.write "\n"

else:
  import readline, history, termios, unsigned

  proc readLineFromStdin*(prompt: string): TaintedString {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    var buffer = readline.readLine(prompt)
    if isNil(buffer): quit(0)
    result = TaintedString($buffer)
    if result.string.len > 0:
      add_history(buffer)
    readline.free(buffer)

  proc readLineFromStdin*(prompt: string, line: var TaintedString): bool {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    var buffer = readline.readLine(prompt)
    if isNil(buffer): quit(0)
    line = TaintedString($buffer)
    if line.string.len > 0:
      add_history(buffer)
    readline.free(buffer)
    # XXX how to determine CTRL+D?
    result = true

  # initialization:
  # disable auto-complete:
  proc doNothing(a, b: cint): cint {.cdecl, procvar.} = discard

  discard readline.bind_key('\t'.ord, doNothing)

  proc readPasswordFromStdin*(prompt: string, password: var TaintedString):
                              bool {.tags: [ReadIOEffect, WriteIOEffect].} =
    password.setLen(0)
    let fd = stdin.getFileHandle()
    var cur, old: Termios
    discard fd.tcgetattr(cur.addr)
    old = cur
    cur.lflag = cur.lflag and not Tcflag(ECHO)
    discard fd.tcsetattr(TCSADRAIN, cur.addr)
    stdout.write prompt
    result = stdin.readLine(password)
    stdout.write "\n"
    discard fd.tcsetattr(TCSADRAIN, old.addr)

proc readPasswordFromStdin*(prompt: string): TaintedString =
  ## Reads a password from stdin without printing it.
  result = TaintedString("")
  discard readPasswordFromStdin(prompt, result)
