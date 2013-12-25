#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Nimrod's standard IO library. It contains high-performance
# routines for reading and writing data to (buffered) files or
# TTYs.

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!


proc fputs(c: cstring, f: TFile) {.importc: "fputs", header: "<stdio.h>", 
  tags: [FWriteIO].}
proc fgets(c: cstring, n: int, f: TFile): cstring {.
  importc: "fgets", header: "<stdio.h>", tags: [FReadIO].}
proc fgetc(stream: TFile): cint {.importc: "fgetc", header: "<stdio.h>",
  tags: [FReadIO].}
proc ungetc(c: cint, f: TFile) {.importc: "ungetc", header: "<stdio.h>",
  tags: [].}
proc putc(c: Char, stream: TFile) {.importc: "putc", header: "<stdio.h>",
  tags: [FWriteIO].}
proc fprintf(f: TFile, frmt: CString) {.importc: "fprintf", 
  header: "<stdio.h>", varargs, tags: [FWriteIO].}
proc strlen(c: cstring): int {.
  importc: "strlen", header: "<string.h>", tags: [].}


# C routine that is used here:
proc fread(buf: Pointer, size, n: int, f: TFile): int {.
  importc: "fread", header: "<stdio.h>", tags: [FReadIO].}
proc fseek(f: TFile, offset: clong, whence: int): int {.
  importc: "fseek", header: "<stdio.h>", tags: [].}
proc ftell(f: TFile): int {.importc: "ftell", header: "<stdio.h>", tags: [].}
proc setvbuf(stream: TFile, buf: pointer, typ, size: cint): cint {.
  importc, header: "<stdio.h>", tags: [].}

{.push stackTrace:off, profiler:off.}
proc write(f: TFile, c: cstring) = fputs(c, f)
{.pop.}

when NoFakeVars:
  when defined(windows):
    const
      IOFBF = cint(0)
      IONBF = cint(4)
  elif defined(macosx) or defined(linux):
    const
      IOFBF = cint(0)
      IONBF = cint(2)
  else:
    {.error: "IOFBF not ported to your platform".}
else:
  var
    IOFBF {.importc: "_IOFBF", nodecl.}: cint
    IONBF {.importc: "_IONBF", nodecl.}: cint

const
  buf_size = 4000

proc raiseEIO(msg: string) {.noinline, noreturn.} =
  sysFatal(EIO, msg)

proc readLine(f: TFile, line: var TaintedString): bool =
  # of course this could be optimized a bit; but IO is slow anyway...
  # and it was difficult to get this CORRECT with Ansi C's methods
  setLen(line.string, 0) # reuse the buffer!
  while True:
    var c = fgetc(f)
    if c < 0'i32:
      if line.len > 0: break
      else: return false
    if c == 10'i32: break # LF
    if c == 13'i32:  # CR
      c = fgetc(f) # is the next char LF?
      if c != 10'i32: ungetc(c, f) # no, put the character back
      break
    add line.string, chr(int(c))
  result = true

proc readLine(f: TFile): TaintedString =
  result = TaintedString(newStringOfCap(80))
  if not readLine(f, result): raiseEIO("EOF reached")

proc write(f: TFile, i: int) = 
  when sizeof(int) == 8:
    fprintf(f, "%lld", i)
  else:
    fprintf(f, "%ld", i)

proc write(f: TFile, i: biggestInt) = 
  when sizeof(biggestint) == 8:
    fprintf(f, "%lld", i)
  else:
    fprintf(f, "%ld", i)
    
proc write(f: TFile, b: bool) =
  if b: write(f, "true")
  else: write(f, "false")
proc write(f: TFile, r: float32) = fprintf(f, "%g", r)
proc write(f: TFile, r: biggestFloat) = fprintf(f, "%g", r)

proc write(f: TFile, c: char) = putc(c, f)
proc write(f: TFile, a: varargs[string, `$`]) =
  for x in items(a): write(f, x)

proc readAllBuffer(file: TFile): string = 
  # This proc is for TFile we want to read but don't know how many
  # bytes we need to read before the buffer is empty.
  result = ""
  var buffer = newString(buf_size)
  var bytesRead = buf_size
  while bytesRead == buf_size:
    bytesRead = readBuffer(file, addr(buffer[0]), buf_size)
    result.add(buffer)
  
proc rawFileSize(file: TFile): int = 
  # this does not raise an error opposed to `getFileSize`
  var oldPos = ftell(file)
  discard fseek(file, 0, 2) # seek the end of the file
  result = ftell(file)
  discard fseek(file, clong(oldPos), 0)

proc readAllFile(file: TFile, len: int): string =
  # We aquire the filesize beforehand and hope it doesn't change.
  # Speeds things up.
  result = newString(int(len))
  if readBuffer(file, addr(result[0]), int(len)) != len:
    raiseEIO("error while reading from file")

proc readAllFile(file: TFile): string =
  var len = rawFileSize(file)
  result = readAllFile(file, len)
  
proc readAll(file: TFile): TaintedString = 
  # Separate handling needed because we need to buffer when we
  # don't know the overall length of the TFile.
  var len = rawFileSize(file)
  if len >= 0:
    result = readAllFile(file, len).TaintedString
  else:
    result = readAllBuffer(file).TaintedString
  
proc readFile(filename: string): TaintedString =
  var f = open(filename)
  try:
    result = readAllFile(f).TaintedString
  finally:
    close(f)

proc writeFile(filename, content: string) =
  var f = open(filename, fmWrite)
  try:
    f.write(content)
  finally:
    close(f)

proc endOfFile(f: TFile): bool =
  # do not blame me; blame the ANSI C standard this is so brain-damaged
  var c = fgetc(f)
  ungetc(c, f)
  return c < 0'i32

proc writeln[Ty](f: TFile, x: varargs[Ty, `$`]) =
  for i in items(x): write(f, i)
  write(f, "\n")

proc rawEcho(x: string) {.inline, compilerproc.} = write(stdout, x)
proc rawEchoNL() {.inline, compilerproc.} = write(stdout, "\n")

# interface to the C procs:

when defined(windows) and not defined(useWinAnsi):
  include "system/widestrs"
  
  proc wfopen(filename, mode: widecstring): pointer {.
    importc: "_wfopen", nodecl.}
  proc wfreopen(filename, mode: widecstring, stream: TFile): TFile {.
    importc: "_wfreopen", nodecl.}

  proc fopen(filename, mode: cstring): pointer =
    var f = newWideCString(filename)
    var m = newWideCString(mode)
    result = wfopen(f, m)

  proc freopen(filename, mode: cstring, stream: TFile): TFile =
    var f = newWideCString(filename)
    var m = newWideCString(mode)
    result = wfreopen(f, m, stream)

else:
  proc fopen(filename, mode: cstring): pointer {.importc: "fopen", noDecl.}
  proc freopen(filename, mode: cstring, stream: TFile): TFile {.
    importc: "freopen", nodecl.}

const
  FormatOpen: array [TFileMode, string] = ["rb", "wb", "w+b", "r+b", "ab"]
    #"rt", "wt", "w+t", "r+t", "at"
    # we always use binary here as for Nimrod the OS line ending
    # should not be translated.


proc open(f: var TFile, filename: string,
          mode: TFileMode = fmRead,
          bufSize: int = -1): bool =
  var p: pointer = fopen(filename, FormatOpen[mode])
  result = (p != nil)
  f = cast[TFile](p)
  if bufSize > 0 and bufSize <= high(cint).int:
    if setvbuf(f, nil, IOFBF, bufSize.cint) != 0'i32:
      sysFatal(EOutOfMemory, "out of memory")
  elif bufSize == 0:
    discard setvbuf(f, nil, IONBF, 0)

proc reopen(f: TFile, filename: string, mode: TFileMode = fmRead): bool = 
  var p: pointer = freopen(filename, FormatOpen[mode], f)
  result = p != nil

proc fdopen(filehandle: TFileHandle, mode: cstring): TFile {.
  importc: pccHack & "fdopen", header: "<stdio.h>".}

proc open(f: var TFile, filehandle: TFileHandle, mode: TFileMode): bool =
  f = fdopen(filehandle, FormatOpen[mode])
  result = f != nil

proc fwrite(buf: pointer, size, n: int, f: TFile): int {.
  importc: "fwrite", noDecl.}

proc readBuffer(f: TFile, buffer: pointer, len: int): int =
  result = fread(buffer, 1, len, f)

proc readBytes(f: TFile, a: var openarray[int8], start, len: int): int =
  result = readBuffer(f, addr(a[start]), len)

proc readChars(f: TFile, a: var openarray[char], start, len: int): int =
  result = readBuffer(f, addr(a[start]), len)

{.push stackTrace:off, profiler:off.}
proc writeBytes(f: TFile, a: openarray[int8], start, len: int): int =
  var x = cast[ptr array[0..1000_000_000, int8]](a)
  result = writeBuffer(f, addr(x[start]), len)
proc writeChars(f: TFile, a: openarray[char], start, len: int): int =
  var x = cast[ptr array[0..1000_000_000, int8]](a)
  result = writeBuffer(f, addr(x[start]), len)
proc writeBuffer(f: TFile, buffer: pointer, len: int): int =
  result = fwrite(buffer, 1, len, f)

proc write(f: TFile, s: string) =
  if writeBuffer(f, cstring(s), s.len) != s.len:
    raiseEIO("cannot write string to file")
{.pop.}

proc setFilePos(f: TFile, pos: int64) =
  if fseek(f, clong(pos), 0) != 0:
    raiseEIO("cannot set file position")

proc getFilePos(f: TFile): int64 =
  result = ftell(f)
  if result < 0: raiseEIO("cannot retrieve file position")

proc getFileSize(f: TFile): int64 =
  var oldPos = getFilePos(f)
  discard fseek(f, 0, 2) # seek the end of the file
  result = getFilePos(f)
  setFilePos(f, oldPos)

{.pop.}
