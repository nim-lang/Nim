#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

import std/private/rdstdin_impl

type
  Completions* = object
    len*: csize_t
    cvec*: cstringArray

  CompletionCallback* = proc (a2: cstring; a3: ptr Completions) {.cdecl.}

{.compile: "linenoise.c".}

proc setCompletionCallback*(a2: CompletionCallback) {.
    importc: "linenoiseSetCompletionCallback".}
proc addCompletion*(a2: ptr Completions; a3: cstring) {.
    importc: "linenoiseAddCompletion".}
proc readLine*(prompt: cstring): cstring {.importc: "linenoise".}
proc historyAdd*(line: cstring): cint {.importc: "linenoiseHistoryAdd",
                                        discardable.}
proc historySetMaxLen*(len: cint): cint {.importc: "linenoiseHistorySetMaxLen".}
proc historySave*(filename: cstring): cint {.importc: "linenoiseHistorySave".}
proc historyLoad*(filename: cstring): cint {.importc: "linenoiseHistoryLoad".}
proc clearScreen*() {.importc: "linenoiseClearScreen".}
proc setMultiLine*(ml: cint) {.importc: "linenoiseSetMultiLine".}
proc printKeyCodes*() {.importc: "linenoisePrintKeyCodes".}

proc free*(s: cstring) {.importc: "free", header: "<stdlib.h>".}

when not defined(windows):
  # C interface
  type LinenoiseStatus = enum
    linenoiseStatus_ctrl_unknown
    linenoiseStatus_ctrl_C
    linenoiseStatus_ctrl_D

  type LinenoiseData* = object
    status*: LinenoiseStatus

  proc linenoiseExtra*(prompt: cstring, data: ptr LinenoiseData): cstring {.importc.}
