#
#
#            Nim's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type
  Completions* {.importc: "linenoiseCompletions", header: "linenoise.h".} = object
    len* {.importc: "len".}: csize
    cvec* {.importc: "cvec".}: cstringArray

  CompletionCallback* = proc (a2: cstring; a3: ptr Completions) {.cdecl.}

{.compile: "linenoise.c".}

proc setCompletionCallback*(a2: ptr CompletionCallback) {.
    importc: "linenoiseSetCompletionCallback", header: "linenoise.h".}
proc addCompletion*(a2: ptr Completions; a3: cstring) {.
    importc: "linenoiseAddCompletion", header: "linenoise.h".}
proc readLine*(prompt: cstring): cstring {.importc: "linenoise", header: "linenoise.h".}
proc historyAdd*(line: cstring): cint {.importc: "linenoiseHistoryAdd",
                                        header: "linenoise.h", discardable.}
proc historySetMaxLen*(len: cint): cint {.importc: "linenoiseHistorySetMaxLen",
    header: "linenoise.h".}
proc historySave*(filename: cstring): cint {.importc: "linenoiseHistorySave",
    header: "linenoise.h".}
proc historyLoad*(filename: cstring): cint {.importc: "linenoiseHistoryLoad",
    header: "linenoise.h".}
proc clearScreen*() {.importc: "linenoiseClearScreen", header: "linenoise.h".}
proc setMultiLine*(ml: cint) {.importc: "linenoiseSetMultiLine",
                               header: "linenoise.h".}
proc printKeyCodes*() {.importc: "linenoisePrintKeyCodes",
  header: "linenoise.h".}

proc free*(s: cstring) {.importc: "free", header: "<stdlib.h>".}
