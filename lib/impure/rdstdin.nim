#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains code for reading from `stdin`:idx:. On UNIX the
## linenoise library is wrapped and set up to provide default key bindings
## (e.g. you can navigate with the arrow keys). On Windows ``system.readLine``
## is used. This suffices because Windows' console already provides the
## wanted functionality.

{.deadCodeElim: on.}  # dce option deprecated

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

  proc readConsoleInputW*(hConsoleInput: HANDLE, lpBuffer: var INPUTRECORD,
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

else:
  import linenoise, termios

  proc readLineFromStdin*(prompt: string): TaintedString {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    var buffer = linenoise.readLine(prompt)
    if isNil(buffer):
      raise newException(IOError, "Linenoise returned nil")
    result = TaintedString($buffer)
    if result.string.len > 0:
      historyAdd(buffer)
    linenoise.free(buffer)

  proc readLineFromStdin*(prompt: string, line: var TaintedString): bool {.
                          tags: [ReadIOEffect, WriteIOEffect].} =
    var buffer = linenoise.readLine(prompt)
    if isNil(buffer):
      line.string.setLen(0)
      return false
    line = TaintedString($buffer)
    if line.string.len > 0:
      historyAdd(buffer)
    linenoise.free(buffer)
    result = true

