include system/inclrtl
import std/oserrors

import oscommon
when supportedSystem:
  export symlinkExists

when defined(nimPreviewSlimSystem):
  import std/[syncio, assertions, widestrs]

when weirdTarget:
  discard
elif defined(windows):
  import std/winlean
  from std/strutils import toHex, toLowerAscii

  const
    reparseHeaderSize = 8
    substituteNameOffsetField = 8
    substituteNameLengthField = 10
    symlinkFlagsField = 16
    mountPointPathBufferOffset = 16
    symlinkPathBufferOffset = 20

  type
    ReparseBuffer = array[MAXIMUM_REPARSE_DATA_BUFFER_SIZE, byte]

    ReparseLayout = object
      pathBufOffset: int
      flagsField: int

    ReparseLinkInfo = object
      tag: int32
      layout: ReparseLayout
      substituteNameOffset: int
      substituteNameLength: int
      flags: int32

    Utf16Slice = object
      ## UTF-16 view inside the reparse payload.
      ## ptr + len kept here because the payload gives us a bounded slice,
      ## not a NUL-terminated `WideCString`.
      ## TODO: use `openArray[Utf16Char]` when view values are no longer experimental.
      data: ptr UncheckedArray[Utf16Char]
      len: int

  template readU16(buf: ReparseBuffer; off: int): uint16 =
    uint16(buf[off]) or (uint16(buf[off + 1]) shl 8)

  template readI32(buf: ReparseBuffer; off: int): int32 =
    cast[int32](
      uint32(buf[off]) or (uint32(buf[off + 1]) shl 8) or
      (uint32(buf[off + 2]) shl 16) or (uint32(buf[off + 3]) shl 24))

  func startsWithAsciiIgnoreCase(s: Utf16Slice; prefix: openArray[char]): bool =
    ## Matches an ASCII prefix against UTF-16 code units.
    ##
    ## This is only correct for ASCII prefixes.
    ## It is not a valid general case-insensitive Unicode comparison
    ## and must not be used for arbitrary UTF-16 text.
    if prefix.len > s.len:
      return false
    var i = 0
    while i < prefix.len:
      let codeUnit = ord(s.data[i])
      if codeUnit > 0x7F or toLowerAscii(char(codeUnit)) != toLowerAscii(prefix[i]):
        return false
      inc i
    true

  proc makeUtf16Slice(buf: ReparseBuffer; startByte, byteLen: int): Utf16Slice =
    Utf16Slice(
      data: cast[ptr UncheckedArray[Utf16Char]](addr buf[startByte]),
      len: byteLen shr 1
    )

  proc decodeWinTarget(wide: Utf16Slice): string =
    if wide.startsWithAsciiIgnoreCase(r"\??\unc\"):
      r"\\" & `$`(wide.data.toOpenArray(8, wide.len - 1), wide.len - 8)
    elif wide.startsWithAsciiIgnoreCase(r"\??\"):
      `$`(wide.data.toOpenArray(4, wide.len - 1), wide.len - 4)
    else:
      `$`(wide.data.toOpenArray(0, wide.len - 1), wide.len)

  template invalidReparseData(path, details: string) =
    raise newException(OSError,
      "expandSymlink: invalid reparse data for " & path & " (" & details & ")")

  proc reparseLayout(tag: int32; symlinkPath: string): ReparseLayout =
    case tag
    of IO_REPARSE_TAG_SYMLINK:
      result = ReparseLayout(
        pathBufOffset: symlinkPathBufferOffset,
        flagsField: symlinkFlagsField
      )
    of IO_REPARSE_TAG_MOUNT_POINT:
      result = ReparseLayout(
        pathBufOffset: mountPointPathBufferOffset,
        flagsField: -1
      )
    else:
      raise newException(OSError,
        "expandSymlink: unsupported reparse tag for " & symlinkPath &
        " (ReparseTag=0x" & toHex(tag) & ")")

  proc parseReparseLinkInfo(buf: ReparseBuffer; bytesReturned: int;
                            symlinkPath: string): ReparseLinkInfo =
    if bytesReturned < reparseHeaderSize:
      invalidReparseData(symlinkPath, "truncated header")

    let
      tag = readI32(buf, 0)
      reparseDataLen = int(readU16(buf, 4))
      wholeDataLen = reparseHeaderSize + reparseDataLen
    if wholeDataLen > bytesReturned:
      invalidReparseData(symlinkPath, "payload exceeds returned size")

    result.tag = tag
    result.layout = reparseLayout(tag, symlinkPath)

    if result.layout.pathBufOffset > wholeDataLen:
      invalidReparseData(symlinkPath, "missing path buffer")

    result.substituteNameOffset = int(readU16(buf, substituteNameOffsetField))
    result.substituteNameLength = int(readU16(buf, substituteNameLengthField))
    if result.substituteNameLength <= 0:
      invalidReparseData(symlinkPath, "empty substitute name")
    if (result.substituteNameOffset and 1) != 0 or
        (result.substituteNameLength and 1) != 0:
      invalidReparseData(symlinkPath, "unaligned UTF-16 substitute name")

    let startByte = result.layout.pathBufOffset + result.substituteNameOffset
    let endByte = startByte + result.substituteNameLength
    if startByte < result.layout.pathBufOffset or endByte < startByte or
        endByte > wholeDataLen:
      invalidReparseData(symlinkPath, "substitute name out of bounds")

    result.flags =
      if result.layout.flagsField >= 0:
        readI32(buf, result.layout.flagsField)
      else:
        0

elif defined(posix):
  import std/posix

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}

when defined(nimscript):
  # for procs already defined in scriptconfig.nim
  template noNimJs(body): untyped = discard
elif defined(js):
  {.pragma: noNimJs, error: "this proc is not available on the js target".}
else:
  {.pragma: noNimJs.}

## .. importdoc:: os.nim

proc createSymlink*(src, dest: string) {.noWeirdTarget.} =
  ## Create a symbolic link at `dest` which points to the item specified
  ## by `src`. On most operating systems, will fail if a link already exists.
  ##
  ## .. warning:: Some OS's (such as Microsoft Windows) restrict the creation
  ##   of symlinks to root users (administrators) or users with developer mode enabled.
  ##
  ## See also:
  ## * `createHardlink proc`_
  ## * `expandSymlink proc`_

  when defined(windows):
    const SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE = 2
    # allows anyone with developer mode on to create a link
    let flag = dirExists(src).int32 or SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
    var wSrc = newWideCString(src)
    var wDst = newWideCString(dest)
    if createSymbolicLinkW(wDst, wSrc, flag) == 0 or getLastError() != 0:
      raiseOSError(osLastError(), $(src, dest))
  else:
    if symlink(src, dest) != 0:
      raiseOSError(osLastError(), $(src, dest))

proc expandSymlink*(symlinkPath: string): string {.noWeirdTarget.} =
  ## Returns the stored target of the symbolic link `symlinkPath`.
  ##
  ## This expands exactly one level of indirection, like POSIX `readlink`.
  ## If the target is itself a symbolic link, it is returned as-is rather than
  ## being expanded further.
  ##
  ## On POSIX, raises `OSError` if `symlinkPath` is not a symbolic link or if
  ## the target cannot be read.
  ##
  ## On Windows, this supports symbolic links and junctions by reading the
  ## reparse point payload directly. Unsupported reparse tags raise `OSError`.
  ##
  ## On Nintendo Switch this is currently a noop: `symlinkPath` is simply
  ## returned, without checking whether it is actually a symbolic link.
  ##
  ## See also:
  ## * `createSymlink proc`_
  when defined(windows):
    let handle = createFileW(
      newWideCString(symlinkPath),
      0'i32,
      FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
      nil,
      OPEN_EXISTING,
      FILE_FLAG_OPEN_REPARSE_POINT or FILE_FLAG_BACKUP_SEMANTICS,
      Handle(0)
    )

    if handle == INVALID_HANDLE_VALUE:
      raiseOSError(osLastError(), "expandSymlink: cannot open " & symlinkPath)

    defer:
      discard closeHandle(handle)

    var buf: ReparseBuffer
    var bytesReturned: DWORD

    if deviceIoControl(
      handle,
      FSCTL_GET_REPARSE_POINT,
      nil, 0'i32,
      addr buf[0], DWORD(buf.len),
      bytesReturned,
      nil
    ) == 0:
      raiseOSError(osLastError(),
        "expandSymlink: DeviceIoControl failed for " & symlinkPath)

    let info = parseReparseLinkInfo(buf, int(bytesReturned), symlinkPath)
    let startByte = info.layout.pathBufOffset + info.substituteNameOffset
    let targetWide = makeUtf16Slice(buf, startByte, info.substituteNameLength)

    if info.tag == IO_REPARSE_TAG_SYMLINK and
      (info.flags and SYMLINK_FLAG_RELATIVE) != 0:
      return `$`(targetWide.data.toOpenArray(0, targetWide.len - 1), targetWide.len)
    decodeWinTarget(targetWide)
  elif defined(nintendoswitch):
    result = symlinkPath
  else:
    var bufLen = 1024
    while true:
      result = newString(bufLen)
      let len = readlink(symlinkPath.cstring, result.cstring, bufLen)
      if len < 0:
        raiseOSError(osLastError(), symlinkPath)
      if len < bufLen:
        result.setLen(len)
        break
      bufLen = bufLen shl 1
