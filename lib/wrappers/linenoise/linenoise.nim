#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  Completions* = object
    len*: csize
    cvec*: cstringArray

  CompletionCallback* = proc (a2: cstring; a3: ptr Completions) {.cdecl.}

{.compile: "linenoise.c".}

proc setCompletionCallback*(a2: ptr CompletionCallback) {.
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

