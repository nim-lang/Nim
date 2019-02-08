#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

include inclrtl

# ----------------- IO Part ------------------------------------------------
type
  CFile {.importc: "FILE", header: "<stdio.h>",
          incompletestruct.} = object
  File* = ptr CFile ## The type representing a file handle.

  FileMode* = enum           ## The file mode when opening a file.
    fmRead,                   ## Open the file for read access only.
    fmWrite,                  ## Open the file for write access only.
                              ## If the file does not exist, it will be
                              ## created. Existing files will be cleared!
    fmReadWrite,              ## Open the file for read and write access.
                              ## If the file does not exist, it will be
                              ## created. Existing files will be cleared!
    fmReadWriteExisting,      ## Open the file for read and write access.
                              ## If the file does not exist, it will not be
                              ## created. The existing file will not be cleared.
    fmAppend                  ## Open the file for writing only; append data
                              ## at the end.

  FileHandle* = cint ## type that represents an OS file handle; this is
                      ## useful for low-level file access

# text file handling:
when not defined(nimscript) and not defined(js):
  var
    stdin* {.importc: "stdin", header: "<stdio.h>".}: File
      ## The standard input stream.
    stdout* {.importc: "stdout", header: "<stdio.h>".}: File
      ## The standard output stream.
    stderr* {.importc: "stderr", header: "<stdio.h>".}: File
      ## The standard error stream.

when defined(useStdoutAsStdmsg):
  template stdmsg*: File = stdout
else:
  template stdmsg*: File = stderr
    ## Template which expands to either stdout or stderr depending on
    ## `useStdoutAsStdmsg` compile-time switch.

when defined(windows):
  proc c_fileno(f: File): cint {.
    importc: "_fileno", header: "<stdio.h>".}
else:
  proc c_fileno(f: File): cint {.
    importc: "fileno", header: "<fcntl.h>".}

when defined(windows):
  proc c_fdopen(filehandle: cint, mode: cstring): File {.
    importc: "_fdopen", header: "<stdio.h>".}
else:
  proc c_fdopen(filehandle: cint, mode: cstring): File {.
    importc: "fdopen", header: "<stdio.h>".}
proc c_fputs(c: cstring, f: File): cint {.
  importc: "fputs", header: "<stdio.h>", tags: [WriteIOEffect].}
proc c_fgets(c: cstring, n: cint, f: File): cstring {.
  importc: "fgets", header: "<stdio.h>", tags: [ReadIOEffect].}
proc c_fgetc(stream: File): cint {.
  importc: "fgetc", header: "<stdio.h>", tags: [ReadIOEffect].}
proc c_ungetc(c: cint, f: File): cint {.
  importc: "ungetc", header: "<stdio.h>", tags: [].}
proc c_putc(c: cint, stream: File): cint {.
  importc: "putc", header: "<stdio.h>", tags: [WriteIOEffect].}
proc c_fflush(f: File): cint {.
  importc: "fflush", header: "<stdio.h>".}
proc c_fclose(f: File): cint {.
  importc: "fclose", header: "<stdio.h>".}
proc c_clearerr(f: File) {.
  importc: "clearerr", header: "<stdio.h>".}
proc c_feof(f: File): cint {.
  importc: "feof", header: "<stdio.h>".}

when not declared(c_fwrite):
  proc c_fwrite(buf: pointer, size, n: csize, f: File): cint {.
    importc: "fwrite", header: "<stdio.h>".}

# C routine that is used here:
proc c_fread(buf: pointer, size, n: csize, f: File): csize {.
  importc: "fread", header: "<stdio.h>", tags: [ReadIOEffect].}
when defined(windows):
  when not defined(amd64):
    proc c_fseek(f: File, offset: int64, whence: cint): cint {.
      importc: "fseek", header: "<stdio.h>", tags: [].}
    proc c_ftell(f: File): int64 {.
      importc: "ftell", header: "<stdio.h>", tags: [].}
  else:
    proc c_fseek(f: File, offset: int64, whence: cint): cint {.
      importc: "_fseeki64", header: "<stdio.h>", tags: [].}
    proc c_ftell(f: File): int64 {.
      importc: "_ftelli64", header: "<stdio.h>", tags: [].}
else:
  proc c_fseek(f: File, offset: int64, whence: cint): cint {.
    importc: "fseeko", header: "<stdio.h>", tags: [].}
  proc c_ftell(f: File): int64 {.
    importc: "ftello", header: "<stdio.h>", tags: [].}
proc c_ferror(f: File): cint {.
  importc: "ferror", header: "<stdio.h>", tags: [].}
proc c_setvbuf(f: File, buf: pointer, mode: cint, size: csize): cint {.
  importc: "setvbuf", header: "<stdio.h>", tags: [].}

proc c_fprintf(f: File, frmt: cstring): cint {.
  importc: "fprintf", header: "<stdio.h>", varargs, discardable.}

template sysFatal(exc, msg) =
  raise newException(exc, msg)

proc raiseEIO(msg: string) {.noinline, noreturn.} =
  sysFatal(IOError, msg)

proc raiseEOF() {.noinline, noreturn.} =
  sysFatal(EOFError, "EOF reached")

proc strerror(errnum: cint): cstring {.importc, header: "<string.h>".}

when not defined(NimScript):
  var
    errno {.importc, header: "<errno.h>".}: cint ## error variable

proc checkErr(f: File) =
  when not defined(NimScript):
    if c_ferror(f) != 0:
      let msg = "errno: " & $errno & " `" & $strerror(errno) & "`"
      c_clearerr(f)
      raiseEIO(msg)
  else:
    # shouldn't happen
    quit(1)

{.push stackTrace:off, profiler:off.}
proc readBuffer*(f: File, buffer: pointer, len: Natural): int {.
  tags: [ReadIOEffect], benign.} =
  ## reads `len` bytes into the buffer pointed to by `buffer`. Returns
  ## the actual number of bytes that have been read which may be less than
  ## `len` (if not as many bytes are remaining), but not greater.
  result = c_fread(buffer, 1, len, f)
  if result != len: checkErr(f)

proc readBytes*(f: File, a: var openArray[int8|uint8], start, len: Natural): int {.
  tags: [ReadIOEffect], benign.} =
  ## reads `len` bytes into the buffer `a` starting at ``a[start]``. Returns
  ## the actual number of bytes that have been read which may be less than
  ## `len` (if not as many bytes are remaining), but not greater.
  result = readBuffer(f, addr(a[start]), len)

proc readChars*(f: File, a: var openArray[char], start, len: Natural): int {.
  tags: [ReadIOEffect], benign.} =
  ## reads `len` bytes into the buffer `a` starting at ``a[start]``. Returns
  ## the actual number of bytes that have been read which may be less than
  ## `len` (if not as many bytes are remaining), but not greater.
  ##
  ## **Warning:** The buffer `a` must be pre-allocated. This can be done
  ## using, for example, ``newString``.
  if (start + len) > len(a):
    raiseEIO("buffer overflow: (start+len) > length of openarray buffer")
  result = readBuffer(f, addr(a[start]), len)

proc write*(f: File, c: cstring) {.tags: [WriteIOEffect], benign.} =
  ## Writes a value to the file `f`. May throw an IO exception.
  discard c_fputs(c, f)
  checkErr(f)

proc writeBuffer*(f: File, buffer: pointer, len: Natural): int {.
  tags: [WriteIOEffect], benign.} =
  ## writes the bytes of buffer pointed to by the parameter `buffer` to the
  ## file `f`. Returns the number of actual written bytes, which may be less
  ## than `len` in case of an error.
  result = c_fwrite(buffer, 1, len, f)
  checkErr(f)

proc writeBytes*(f: File, a: openArray[int8|uint8], start, len: Natural): int {.
  tags: [WriteIOEffect], benign.} =
  ## writes the bytes of ``a[start..start+len-1]`` to the file `f`. Returns
  ## the number of actual written bytes, which may be less than `len` in case
  ## of an error.
  var x = cast[ptr UncheckedArray[int8]](a)
  result = writeBuffer(f, addr(x[int(start)]), len)

proc writeChars*(f: File, a: openArray[char], start, len: Natural): int {.
  tags: [WriteIOEffect], benign.} =
  ## writes the bytes of ``a[start..start+len-1]`` to the file `f`. Returns
  ## the number of actual written bytes, which may be less than `len` in case
  ## of an error.
  var x = cast[ptr UncheckedArray[int8]](a)
  result = writeBuffer(f, addr(x[int(start)]), len)

proc write*(f: File, s: string) {.tags: [WriteIOEffect], benign.} =
  if writeBuffer(f, cstring(s), s.len) != s.len:
    raiseEIO("cannot write string to file")
{.pop.}

when NoFakeVars:
  when defined(windows):
    const
      IOFBF = cint(0)
      IONBF = cint(4)
  else:
    # On all systems I could find, including Linux, Mac OS X, and the BSDs
    const
      IOFBF = cint(0)
      IONBF = cint(2)
else:
  var
    IOFBF {.importc: "_IOFBF", nodecl.}: cint
    IONBF {.importc: "_IONBF", nodecl.}: cint

const
  BufSize = 4000

proc close*(f: File) {.tags: [], gcsafe.} =
  ## Closes the file.
  if not f.isNil:
    discard c_fclose(f)

proc readChar*(f: File): char {.tags: [ReadIOEffect].} =
  ## Reads a single character from the stream `f`. Should not be used in
  ## performance sensitive code.
  let x = c_fgetc(f)
  if x < 0:
    checkErr(f)
    raiseEOF()
  result = char(x)

proc flushFile*(f: File) {.tags: [WriteIOEffect].} =
  ## Flushes `f`'s buffer.
  discard c_fflush(f)

proc getFileHandle*(f: File): FileHandle =
  ## returns the OS file handle of the file ``f``. This is only useful for
  ## platform specific programming.
  c_fileno(f)

proc readLine*(f: File, line: var TaintedString): bool {.tags: [ReadIOEffect],
              benign.} =
  ## reads a line of text from the file `f` into `line`. May throw an IO
  ## exception.
  ## A line of text may be delimited by ``LF`` or ``CRLF``. The newline
  ## character(s) are not part of the returned string. Returns ``false``
  ## if the end of the file has been reached, ``true`` otherwise. If
  ## ``false`` is returned `line` contains no new data.
  proc c_memchr(s: pointer, c: cint, n: csize): pointer {.
    importc: "memchr", header: "<string.h>".}

  var pos = 0

  # Use the currently reserved space for a first try
  var sp = max(line.string.len, 80)
  line.string.setLen(sp)

  while true:
    # memset to \L so that we can tell how far fgets wrote, even on EOF, where
    # fgets doesn't append an \L
    for i in 0..<sp: line.string[pos+i] = '\L'

    var fgetsSuccess = c_fgets(addr line.string[pos], sp.cint, f) != nil
    if not fgetsSuccess: checkErr(f)
    let m = c_memchr(addr line.string[pos], '\L'.ord, sp)
    if m != nil:
      # \l found: Could be our own or the one by fgets, in any case, we're done
      var last = cast[ByteAddress](m) - cast[ByteAddress](addr line.string[0])
      if last > 0 and line.string[last-1] == '\c':
        line.string.setLen(last-1)
        return last > 1 or fgetsSuccess
        # We have to distinguish between two possible cases:
        # \0\l\0 => line ending in a null character.
        # \0\l\l => last line without newline, null was put there by fgets.
      elif last > 0 and line.string[last-1] == '\0':
        if last < pos + sp - 1 and line.string[last+1] != '\0':
          dec last
      line.string.setLen(last)
      return last > 0 or fgetsSuccess
    else:
      # fgets will have inserted a null byte at the end of the string.
      dec sp
    # No \l found: Increase buffer and read more
    inc pos, sp
    sp = 128 # read in 128 bytes at a time
    line.string.setLen(pos+sp)

proc readLine*(f: File): TaintedString  {.tags: [ReadIOEffect], benign.} =
  ## reads a line of text from the file `f`. May throw an IO exception.
  ## A line of text may be delimited by ``LF`` or ``CRLF``. The newline
  ## character(s) are not part of the returned string.
  result = TaintedString(newStringOfCap(80))
  if not readLine(f, result): raiseEOF()

proc write*(f: File, i: int) {.tags: [WriteIOEffect], benign.} =
  when sizeof(int) == 8:
    if c_fprintf(f, "%lld", i) < 0: checkErr(f)
  else:
    if c_fprintf(f, "%ld", i) < 0: checkErr(f)

proc write*(f: File, i: BiggestInt) {.tags: [WriteIOEffect], benign.} =
  when sizeof(BiggestInt) == 8:
    if c_fprintf(f, "%lld", i) < 0: checkErr(f)
  else:
    if c_fprintf(f, "%ld", i) < 0: checkErr(f)

proc write*(f: File, b: bool) {.tags: [WriteIOEffect], benign.} =
  if b: write(f, "true")
  else: write(f, "false")
proc write*(f: File, r: float32) {.tags: [WriteIOEffect], benign.} =
  if c_fprintf(f, "%.16g", r) < 0: checkErr(f)
proc write*(f: File, r: BiggestFloat) {.tags: [WriteIOEffect], benign.} =
  if c_fprintf(f, "%.16g", r) < 0: checkErr(f)

proc write*(f: File, c: char) {.tags: [WriteIOEffect], benign.} =
  discard c_putc(cint(c), f)

proc write*(f: File, a: varargs[string, `$`]) {.tags: [WriteIOEffect], benign.} =
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

proc rawFileSize(file: File): int64 =
  # this does not raise an error opposed to `getFileSize`
  var oldPos = c_ftell(file)
  discard c_fseek(file, 0, 2) # seek the end of the file
  result = c_ftell(file)
  discard c_fseek(file, oldPos, 0)

proc endOfFile*(f: File): bool {.tags: [], benign.} =
  ## Returns true iff `f` is at the end.
  var c = c_fgetc(f)
  discard c_ungetc(c, f)
  return c < 0'i32
  #result = c_feof(f) != 0

proc readAllFile(file: File, len: int64): string =
  # We acquire the filesize beforehand and hope it doesn't change.
  # Speeds things up.
  result = newString(len)
  let bytes = readBuffer(file, addr(result[0]), len)
  if endOfFile(file):
    if bytes < len:
      result.setLen(bytes)
  else:
    # We read all the bytes but did not reach the EOF
    # Try to read it as a buffer
    result.add(readAllBuffer(file))

proc readAllFile(file: File): string =
  var len = rawFileSize(file)
  result = readAllFile(file, len)

proc readAll*(file: File): TaintedString {.tags: [ReadIOEffect], benign.} =
  ## Reads all data from the stream `file`.
  ##
  ## Raises an IO exception in case of an error. It is an error if the
  ## current file position is not at the beginning of the file.

  # Separate handling needed because we need to buffer when we
  # don't know the overall length of the File.
  when declared(stdin):
    let len = if file != stdin: rawFileSize(file) else: -1
  else:
    let len = rawFileSize(file)
  if len > 0:
    result = readAllFile(file, len).TaintedString
  else:
    result = readAllBuffer(file).TaintedString

proc writeLn[Ty](f: File, x: varargs[Ty, `$`]) =
  for i in items(x):
    write(f, i)
  write(f, "\n")

proc writeLine*[Ty](f: File, x: varargs[Ty, `$`]) {.inline,
                          tags: [WriteIOEffect], benign.} =
  ## writes the values `x` to `f` and then writes "\\n".
  ## May throw an IO exception.
  for i in items(x):
    write(f, i)
  write(f, "\n")

# interface to the C procs:

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
  FormatOpen: array[FileMode, string] = ["rb", "wb", "w+b", "r+b", "ab"]
    #"rt", "wt", "w+t", "r+t", "at"
    # we always use binary here as for Nim the OS line ending
    # should not be translated.

when defined(posix) and not defined(nimscript):
  when defined(linux) and defined(amd64):
    type
      Mode {.importc: "mode_t", header: "<sys/types.h>".} = cint

      # fillers ensure correct size & offsets
      Stat {.importc: "struct stat",
              header: "<sys/stat.h>", final, pure.} = object ## struct stat
        filler_1: array[24, char]
        st_mode: Mode        ## Mode of file
        filler_2: array[144 - 24 - 4, char]

    proc S_ISDIR(m: Mode): bool =
      ## Test for a directory.
      (m and 0o170000) == 0o40000

  else:
    type
      Mode {.importc: "mode_t", header: "<sys/types.h>".} = cint

      Stat {.importc: "struct stat",
               header: "<sys/stat.h>", final, pure.} = object ## struct stat
        st_mode: Mode        ## Mode of file

    proc S_ISDIR(m: Mode): bool {.importc, header: "<sys/stat.h>".}
      ## Test for a directory.

  proc c_fstat(a1: cint, a2: var Stat): cint {.
    importc: "fstat", header: "<sys/stat.h>".}


proc open*(f: var File, filename: string,
          mode: FileMode = fmRead,
          bufSize: int = -1): bool  {.tags: [], raises: [], benign.} =
  ## Opens a file named `filename` with given `mode`.
  ##
  ## Default mode is readonly. Returns true iff the file could be opened.
  ## This throws no exception if the file could not be opened.
  var p: pointer = fopen(filename, FormatOpen[mode])
  if p != nil:
    when defined(posix) and not defined(nimscript):
      # How `fopen` handles opening a directory is not specified in ISO C and
      # POSIX. We do not want to handle directories as regular files that can
      # be opened.
      var f2 = cast[File](p)
      var res: Stat
      if c_fstat(getFileHandle(f2), res) >= 0'i32 and S_ISDIR(res.st_mode):
        close(f2)
        return false
    result = true
    f = cast[File](p)
    if bufSize > 0 and bufSize <= high(cint).int:
      discard c_setvbuf(f, nil, IOFBF, bufSize.cint)
    elif bufSize == 0:
      discard c_setvbuf(f, nil, IONBF, 0)

proc reopen*(f: File, filename: string, mode: FileMode = fmRead): bool {.
  tags: [], benign.} =
  ## reopens the file `f` with given `filename` and `mode`. This
  ## is often used to redirect the `stdin`, `stdout` or `stderr`
  ## file variables.
  ##
  ## Default mode is readonly. Returns true iff the file could be reopened.
  var p: pointer = freopen(filename, FormatOpen[mode], f)
  result = p != nil

proc open*(f: var File, filehandle: FileHandle,
           mode: FileMode = fmRead): bool {.tags: [], raises: [], benign.} =
  ## Creates a ``File`` from a `filehandle` with given `mode`.
  ##
  ## Default mode is readonly. Returns true iff the file could be opened.

  f = c_fdopen(filehandle, FormatOpen[mode])
  result = f != nil

proc open*(filename: string,
            mode: FileMode = fmRead, bufSize: int = -1): File =
  ## Opens a file named `filename` with given `mode`.
  ##
  ## Default mode is readonly. Raises an ``IOError`` if the file
  ## could not be opened.
  if not open(result, filename, mode, bufSize):
    sysFatal(IOError, "cannot open: " & filename)

proc setFilePos*(f: File, pos: int64, relativeTo: FileSeekPos = fspSet) {.benign.} =
  ## sets the position of the file pointer that is used for read/write
  ## operations. The file's first byte has the index zero.
  if c_fseek(f, pos, cint(relativeTo)) != 0:
    raiseEIO("cannot set file position")

proc getFilePos*(f: File): int64 {.benign.} =
  ## retrieves the current position of the file pointer that is used to
  ## read from the file `f`. The file's first byte has the index zero.
  result = c_ftell(f)
  if result < 0: raiseEIO("cannot retrieve file position")

proc getFileSize*(f: File): int64 {.tags: [ReadIOEffect], benign.} =
  ## retrieves the file size (in bytes) of `f`.
  var oldPos = getFilePos(f)
  discard c_fseek(f, 0, 2) # seek the end of the file
  result = getFilePos(f)
  setFilePos(f, oldPos)

proc setStdIoUnbuffered*() {.tags: [], benign.} =
  ## Configures `stdin`, `stdout` and `stderr` to be unbuffered.
  when declared(stdout):
    discard c_setvbuf(stdout, nil, IONBF, 0)
  when declared(stderr):
    discard c_setvbuf(stderr, nil, IONBF, 0)
  when declared(stdin):
    discard c_setvbuf(stdin, nil, IONBF, 0)

when declared(stdout):
  when defined(windows) and compileOption("threads"):
    const insideRLocksModule = false
    include "system/syslocks"

    var echoLock: SysLock
    initSysLock echoLock

  proc echoBinSafe(args: openArray[string]) {.compilerProc.} =
    # flockfile deadlocks some versions of Android 5.x.x
    when not defined(windows) and not defined(android) and not defined(nintendoswitch):
      proc flockfile(f: File) {.importc, noDecl.}
      proc funlockfile(f: File) {.importc, noDecl.}
      flockfile(stdout)
    when defined(windows) and compileOption("threads"):
      acquireSys echoLock
    for s in args:
      discard c_fwrite(s.cstring, s.len, 1, stdout)
    const linefeed = "\n" # can be 1 or more chars
    discard c_fwrite(linefeed.cstring, linefeed.len, 1, stdout)
    discard c_fflush(stdout)
    when not defined(windows) and not defined(android) and not defined(nintendoswitch):
      funlockfile(stdout)
    when defined(windows) and compileOption("threads"):
      releaseSys echoLock


when defined(windows) and not defined(nimscript):
  # work-around C's sucking abstraction:
  # BUGFIX: stdin and stdout should be binary files!
  proc c_setmode(handle, mode: cint) {.
    importc: when defined(bcc): "setmode" else: "_setmode",
    header: "<io.h>".}
  var
    O_BINARY {.importc: "_O_BINARY", header:"<fcntl.h>".}: cint

  # we use binary mode on Windows:
  c_setmode(c_fileno(stdin), O_BINARY)
  c_setmode(c_fileno(stdout), O_BINARY)
  c_setmode(c_fileno(stderr), O_BINARY)


proc readFile*(filename: string): TaintedString {.tags: [ReadIOEffect], benign.} =
  ## Opens a file named `filename` for reading, calls `readAll
  ## <#readAll>`_ and closes the file afterwards. Returns the string.
  ## Raises an IO exception in case of an error. If # you need to call
  ## this inside a compile time macro you can use `staticRead
  ## <#staticRead>`_.
  var f: File
  if open(f, filename):
    try:
      result = readAll(f).TaintedString
    finally:
      close(f)
  else:
    sysFatal(IOError, "cannot open: " & filename)

proc writeFile*(filename, content: string) {.tags: [WriteIOEffect], benign.} =
  ## Opens a file named `filename` for writing. Then writes the
  ## `content` completely to the file and closes the file afterwards.
  ## Raises an IO exception in case of an error.
  var f: File
  if open(f, filename, fmWrite):
    try:
      f.write(content)
    finally:
      close(f)
  else:
    sysFatal(IOError, "cannot open: " & filename)

iterator lines*(filename: string): TaintedString {.tags: [ReadIOEffect].} =
  ## Iterates over any line in the file named `filename`.
  ##
  ## If the file does not exist `IOError` is raised. The trailing newline
  ## character(s) are removed from the iterated lines. Example:
  ##
  ## .. code-block:: nim
  ##   import strutils
  ##
  ##   proc transformLetters(filename: string) =
  ##     var buffer = ""
  ##     for line in filename.lines:
  ##       buffer.add(line.replace("a", "0") & '\x0A')
  ##     writeFile(filename, buffer)
  var f = open(filename, bufSize=8000)
  defer: close(f)
  var res = TaintedString(newStringOfCap(80))
  while f.readLine(res): yield res

iterator lines*(f: File): TaintedString {.tags: [ReadIOEffect].} =
  ## Iterate over any line in the file `f`.
  ##
  ## The trailing newline character(s) are removed from the iterated lines.
  ## Example:
  ##
  ## .. code-block:: nim
  ##   proc countZeros(filename: File): tuple[lines, zeros: int] =
  ##     for line in filename.lines:
  ##       for letter in line:
  ##         if letter == '0':
  ##           result.zeros += 1
  ##       result.lines += 1
  var res = TaintedString(newStringOfCap(80))
  while f.readLine(res): yield res
