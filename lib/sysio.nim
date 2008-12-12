#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2006 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## Nimrod's standard IO library. It contains high-performance
## routines for reading and writing data to (buffered) files or
## TTYs.

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!


proc fputs(c: cstring, f: TFile) {.importc: "fputs", noDecl.}
proc fgets(c: cstring, n: int, f: TFile): cstring {.importc: "fgets", noDecl.}
proc fgetc(stream: TFile): int {.importc: "fgetc", nodecl.}
proc ungetc(c: cint, f: TFile) {.importc: "ungetc", nodecl.}
proc putc(c: Char, stream: TFile) {.importc: "putc", nodecl.}
proc fprintf(f: TFile, frmt: CString) {.importc: "fprintf", nodecl, varargs.}
proc strlen(c: cstring): int {.importc: "strlen", nodecl.}

proc setvbuf(stream: TFile, buf: pointer, typ, size: cint): cint {.
  importc, nodecl.}

proc write(f: TFile, c: cstring) = fputs(c, f)

var
  IOFBF {.importc: "_IOFBF", nodecl.}: cint
  IONBF {.importc: "_IONBF", nodecl.}: cint

proc rawReadLine(f: TFile, result: var string) =
  # of course this could be optimized a bit; but IO is slow anyway...
  # and it was difficult to get this CORRECT with Ansi C's methods
  var
    c: cint
  setLen(result, 0) # reuse the buffer!
  while True:
    c = fgetc(f)
    if c < 0'i32: break # EOF
    if c == 10'i32: break # LF
    if c == 13'i32:  # CR
      c = fgetc(f) # is the next char LF?
      if c != 10'i32: ungetc(c, f) # no, put the character back
      break
    add result, chr(int(c))

proc readLine(f: TFile): string =
  result = ""
  rawReadLine(f, result)

proc write(f: TFile, s: string) = fputs(s, f)
proc write(f: TFile, i: int) = fprintf(f, "%ld", i)
proc write(f: TFile, b: bool) =
  if b: write(f, "true")
  else: write(f, "false")
proc write(f: TFile, r: float) = fprintf(f, "%g", r)
proc write(f: TFile, c: Char) = putc(c, f)
proc write(f: TFile, a: openArray[string]) =
  for x in items(a): write(f, x)

proc readFile(filename: string): string =
  var f: TFile
  try:
    if openFile(f, filename):
      var len = getFileSize(f)
      if len < high(int):
        result = newString(int(len))
        if readBuffer(f, addr(result[0]), int(len)) != len:
          result = nil
      closeFile(f)
    else:
      result = nil
  except EIO:
    result = nil

proc EndOfFile(f: TFile): bool =
  # do not blame me; blame the ANSI C standard this is so brain-damaged
  var
    c: int
  c = fgetc(f)
  ungetc(c, f)
  return c == -1

proc writeln[Ty](f: TFile, x: Ty) =
  write(f, x)
  write(f, "\n")

proc writeln[Ty](f: TFile, x: openArray[Ty]) =
  write(f, x)
  write(f, "\n")

proc echo[Ty](x: Ty) = writeln(stdout, x)

# interface to the C procs:
proc fopen(filename, mode: CString): pointer {.importc: "fopen", noDecl.}

const
  FormatOpen: array [TFileMode, string] = ["rb", "wb", "w+b", "r+b", "ab"]
    #"rt", "wt", "w+t", "r+t", "at"
    # we always use binary here as for Nimrod the OS line ending
    # should not be translated.


proc OpenFile(f: var TFile, filename: string,
              mode: TFileMode = fmRead,
              bufSize: int = -1): Bool =
  var
    p: pointer
  p = fopen(filename, FormatOpen[mode])
  result = (p != nil)
  f = cast[TFile](p)
  if bufSize > 0:
    if setvbuf(f, nil, IOFBF, bufSize) != 0'i32:
      raise newException(EOutOfMemory, "out of memory")
  elif bufSize == 0:
    discard setvbuf(f, nil, IONBF, 0)

proc fdopen(filehandle: TFileHandle, mode: cstring): TFile {.
  importc: pccHack & "fdopen", header: "<stdio.h>".}

proc openFile(f: var TFile, filehandle: TFileHandle, mode: TFileMode): bool =
  f = fdopen(filehandle, FormatOpen[mode])
  result = f != nil

# C routine that is used here:
proc fread(buf: Pointer, size, n: int, f: TFile): int {.
  importc: "fread", noDecl.}
proc fseek(f: TFile, offset: clong, whence: int): int {.
  importc: "fseek", noDecl.}
proc ftell(f: TFile): int {.importc: "ftell", noDecl.}

proc fwrite(buf: Pointer, size, n: int, f: TFile): int {.
  importc: "fwrite", noDecl.}

proc readBuffer(f: TFile, buffer: pointer, len: int): int =
  result = fread(buffer, 1, len, f)

proc ReadBytes(f: TFile, a: var openarray[byte], start, len: int): int =
  result = readBuffer(f, addr(a[start]), len)

proc ReadChars(f: TFile, a: var openarray[char], start, len: int): int =
  result = readBuffer(f, addr(a[start]), len)

proc writeBytes(f: TFile, a: openarray[byte], start, len: int): int =
  var x = cast[ptr array[0..1000_000_000, byte]](a)
  result = writeBuffer(f, addr(x[start]), len)
proc writeChars(f: TFile, a: openarray[char], start, len: int): int =
  var x = cast[ptr array[0..1000_000_000, byte]](a)
  result = writeBuffer(f, addr(x[start]), len)
proc writeBuffer(f: TFile, buffer: pointer, len: int): int =
  result = fwrite(buffer, 1, len, f)

proc setFilePos(f: TFile, pos: int64) =
  if fseek(f, clong(pos), 0) != 0:
    raise newException(EIO, "cannot set file position")

proc getFilePos(f: TFile): int64 =
  result = ftell(f)
  if result < 0: raise newException(EIO, "cannot retrieve file position")

proc getFileSize(f: TFile): int64 =
  var oldPos = getFilePos(f)
  discard fseek(f, 0, 2) # seek the end of the file
  result = getFilePos(f)
  setFilePos(f, oldPos)

{.pop.}
