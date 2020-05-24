##[
consider moving to std/terminal once stablized
we could depend on isatty, but `cat` on a log file would behave like the terminal.
]##

const enableErasableLines* = true

when enableErasableLines:
  import std/terminal

  var erasableLines = 0
    ## number of lines we can safely remove; it's ok to remove less.
    ## it's a global property, not ConfigRef specific
    ## There's only 1 terminal for both stdout/stderr, so it doesn't make sense
    ## to distinguish between them.

  proc eraseLines(cfile: File) =
    let n = erasableLines
    for i in 0..<n:
      # terminal code amounts to: "\e[A\e[2K"
      cursorUp(cfile)
      eraseLine(cfile)

  type TermPos = object
    ## 0-based
    col: int
    row: int
    cols: int

  proc updateTermPos*(result: var TermPos, s: openArray[char]) =
    for i in 0..<s.len:
      if s[i] == '\n':
        result.col = 0
        result.row.inc
      else:
        ## this could use `wcswidth` for wide characters.
        result.col.inc
        if result.col > result.cols:
          result.col = 0
          result.row.inc

  proc initTermPos(): TermPos =
    result.cols = terminalWidth() # don't cache in case window is resized; it's cheap

  proc updateErasableLines(a: TermPos) =
    erasableLines += a.row

  proc updateErasableLinesFromStrs*(strs: openArray[string]) =
    var pos = initTermPos()
    for i in 0..<strs.len:
      updateTermPos(pos, strs[i])
    updateErasableLines(pos)

  proc flushErasableImpl(cfile: File, erase = false) =
    ## safe to call multiple times.
    ## erase=false is useful if you want to keep the last erasable lines
    if erasableLines > 0:
      if erase:
        eraseLines(cfile)
      erasableLines = 0

else:
  var lastMsgWasDot = false

  proc flushErasableImpl(cfile: File, erase = false) =
    if lastMsgWasDot:
      write(cfile, "\n")
      lastMsgWasDot = false

  proc writeErasable*(cfile: File; s: string) =
    if cfile != nil:
      write(cfile, s)
      flushFile(cfile)
      lastMsgWasDot = true # subsequent writes need `flushErasable`

proc flushErasable*(cfile: File, erase = false) =
  flushErasableImpl(cfile, erase)
