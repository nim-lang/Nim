#
#
#            Nim's Runtime Library
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


# Nim's standard IO library. It contains high-performance
# routines for reading and writing data to (buffered) files or
# TTYs.

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!


proc fputs(c: cstring, f: File) {.importc: "fputs", header: "<stdio.h>", 
  tags: [WriteIOEffect].}
proc fgets(c: cstring, n: int, f: File): cstring {.
  importc: "fgets", header: "<stdio.h>", tags: [ReadIOEffect].}
proc fgetc(stream: File): cint {.importc: "fgetc", header: "<stdio.h>",
  tags: [ReadIOEffect].}
proc ungetc(c: cint, f: File) {.importc: "ungetc", header: "<stdio.h>",
  tags: [].}
proc putc(c: char, stream: File) {.importc: "putc", header: "<stdio.h>",
  tags: [WriteIOEffect].}
proc fprintf(f: File, frmt: cstring) {.importc: "fprintf", 
  header: "<stdio.h>", varargs, tags: [WriteIOEffect].}
proc strlen(c: cstring): int {.
  importc: "strlen", header: "<string.h>", tags: [].}


# C routine that is used here:
proc fread(buf: pointer, size, n: int, f: File): int {.
  importc: "fread", header: "<stdio.h>", tags: [ReadIOEffect].}
proc fseek(f: File, offset: clong, whence: int): int {.
  importc: "fseek", header: "<stdio.h>", tags: [].}
proc ftell(f: File): int {.importc: "ftell", header: "<stdio.h>", tags: [].}
proc setvbuf(stream: File, buf: pointer, typ, size: cint): cint {.
  importc, header: "<stdio.h>", tags: [].}

{.push stackTrace:off, profiler:off.}
proc write(f: File, c: cstring) = fputs(c, f)
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
  BufSize = 4000

proc raiseEIO(msg: string) {.noinline, noreturn.} =
  sysFatal(IOError, msg)

proc readLine(f: File, line: var TaintedString): bool =
  # of course this could be optimized a bit; but IO is slow anyway...
  # and it was difficult to get this CORRECT with Ansi C's methods
  setLen(line.string, 0) # reuse the buffer!
  while true:
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

proc readLine(f: File): TaintedString =
  result = TaintedString(newStringOfCap(80))
  if not readLine(f, result): raiseEIO("EOF reached")

proc write(f: File, i: int) = 
  when sizeof(int) == 8:
    fprintf(f, "%lld", i)
  else:
    fprintf(f, "%ld", i)

proc write(f: File, i: BiggestInt) = 
  when sizeof(BiggestInt) == 8:
    fprintf(f, "%lld", i)
  else:
    fprintf(f, "%ld", i)
    
proc write(f: File, b: bool) =
  if b: write(f, "true")
  else: write(f, "false")
proc write(f: File, r: float32) = fprintf(f, "%g", r)
proc write(f: File, r: BiggestFloat) = fprintf(f, "%g", r)

proc write(f: File, c: char) = putc(c, f)
proc write(f: File, a: varargs[string, `$`]) =
  for x in items(a): write(f, x)

proc readAllBuffer(file: File): string = 
  # This proc is for File we want to read but don't know how many
  # bytes we need to read before the buffer is empty.
  result = ""
  var buffer = newString(BufSize)
  while true:
    var bytesRead = readBuffer(file, addr(buffer[0]), BufSize)
    if bytesRead == BufSize:
      result.add(buffer)
    else:
      buffer.setLen(bytesRead)
      result.add(buffer)
      break
  
proc rawFileSize(file: File): int = 
  # this does not raise an error opposed to `getFileSize`
  var oldPos = ftell(file)
  discard fseek(file, 0, 2) # seek the end of the file
  result = ftell(file)
  discard fseek(file, clong(oldPos), 0)

proc readAllFile(file: File, len: int): string =
  # We acquire the filesize beforehand and hope it doesn't change.
  # Speeds things up.
  result = newString(int(len))
  if readBuffer(file, addr(result[0]), int(len)) != len:
    raiseEIO("error while reading from file")

proc readAllFile(file: File): string =
  var len = rawFileSize(file)
  result = readAllFile(file, len)
  
proc readAll(file: File): TaintedString = 
  # Separate handling needed because we need to buffer when we
  # don't know the overall length of the File.
  let len = if file != stdin: rawFileSize(file) else: -1
  if len > 0:
    result = readAllFile(file, len).TaintedString
  else:
    result = readAllBuffer(file).TaintedString
  
proc readFile(filename: string): TaintedString =
  var f = open(filename)
  try:
    result = readAll(f).TaintedString
  finally:
    close(f)

proc writeFile(filename, content: string) =
  var f = open(filename, fmWrite)
  try:
    f.write(content)
  finally:
    close(f)

proc endOfFile(f: File): bool =
  # do not blame me; blame the ANSI C standard this is so brain-damaged
  var c = fgetc(f)
  ungetc(c, f)
  return c < 0'i32

proc writeln[Ty](f: File, x: varargs[Ty, `$`]) =
  for i in items(x): write(f, i)
  write(f, "\n")

proc rawEcho(x: string) {.inline, compilerproc.} = write(stdout, x)
proc rawEchoNL() {.inline, compilerproc.} = write(stdout, "\n")

# interface to the C procs:

when (defined(windows) and not defined(useWinAnsi)) or defined(nimdoc):
  include "system/widestrs"

when defined(windows) and not defined(useWinAnsi):
  when defined(cpp):
    proc wfopen(filename, mode: WideCString): pointer {.
      importcpp: "_wfopen((const wchar_t*)#, (const wchar_t*)#)", nodecl.}
    proc wfreopen(filename, mode: WideCString, stream: File): File {.
      importcpp: "_wfreopen((const wchar_t*)#, (const wchar_t*)#, #)", nodecl.}
  else:
    proc wfopen(filename, mode: WideCString): pointer {.
      importc: "_wfopen", nodecl.}
    proc wfreopen(filename, mode: WideCString, stream: File): File {.
      importc: "_wfreopen", nodecl.}

  proc fopen(filename, mode: cstring): pointer =
    var f = newWideCString(filename)
    var m = newWideCString(mode)
    result = wfopen(f, m)

  proc freopen(filename, mode: cstring, stream: File): File =
    var f = newWideCString(filename)
    var m = newWideCString(mode)
    result = wfreopen(f, m, stream)

else:
  proc fopen(filename, mode: cstring): pointer {.importc: "fopen", noDecl.}
  proc freopen(filename, mode: cstring, stream: File): File {.
    importc: "freopen", nodecl.}

const
  FormatOpen: array [FileMode, string] = ["rb", "wb", "w+b", "r+b", "ab"]
    #"rt", "wt", "w+t", "r+t", "at"
    # we always use binary here as for Nim the OS line ending
    # should not be translated.


proc open(f: var File, filename: string,
          mode: FileMode = fmRead,
          bufSize: int = -1): bool =
  var p: pointer = fopen(filename, FormatOpen[mode])
  if p != nil:
    result = true
    f = cast[File](p)
    if bufSize > 0 and bufSize <= high(cint).int:
      discard setvbuf(f, nil, IOFBF, bufSize.cint)
    elif bufSize == 0:
      discard setvbuf(f, nil, IONBF, 0)

proc reopen(f: File, filename: string, mode: FileMode = fmRead): bool = 
  var p: pointer = freopen(filename, FormatOpen[mode], f)
  result = p != nil

proc fdopen(filehandle: FileHandle, mode: cstring): File {.
  importc: pccHack & "fdopen", header: "<stdio.h>".}

proc open(f: var File, filehandle: FileHandle, mode: FileMode): bool =
  f = fdopen(filehandle, FormatOpen[mode])
  result = f != nil

proc fwrite(buf: pointer, size, n: int, f: File): int {.
  importc: "fwrite", noDecl.}

proc readBuffer(f: File, buffer: pointer, len: int): int =
  result = fread(buffer, 1, len, f)

proc readBytes(f: File, a: var openArray[int8|uint8], start, len: int): int =
  result = readBuffer(f, addr(a[start]), len)

proc readChars(f: File, a: var openArray[char], start, len: int): int =
  result = readBuffer(f, addr(a[start]), len)

{.push stackTrace:off, profiler:off.}
proc writeBytes(f: File, a: openArray[int8|uint8], start, len: int): int =
  var x = cast[ptr array[0..1000_000_000, int8]](a)
  result = writeBuffer(f, addr(x[start]), len)
proc writeChars(f: File, a: openArray[char], start, len: int): int =
  var x = cast[ptr array[0..1000_000_000, int8]](a)
  result = writeBuffer(f, addr(x[start]), len)
proc writeBuffer(f: File, buffer: pointer, len: int): int =
  result = fwrite(buffer, 1, len, f)

proc write(f: File, s: string) =
  if writeBuffer(f, cstring(s), s.len) != s.len:
    raiseEIO("cannot write string to file")
{.pop.}

proc setFilePos(f: File, pos: int64) =
  if fseek(f, clong(pos), 0) != 0:
    raiseEIO("cannot set file position")

proc getFilePos(f: File): int64 =
  result = ftell(f)
  if result < 0: raiseEIO("cannot retrieve file position")

proc getFileSize(f: File): int64 =
  var oldPos = getFilePos(f)
  discard fseek(f, 0, 2) # seek the end of the file
  result = getFilePos(f)
  setFilePos(f, oldPos)

{.pop.}
