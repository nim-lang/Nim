import
  ".." / [ pathutils ],
  packed_ast, frosty, supersnappy,
  std / [ strutils ]

##[

read/write modules to/from disk

]##

const
  version =
    when defined(release): NimVersion else: CompileDate & CompileTime
  maxBufSize = -1  # auto

proc writeIn*(m: Module; fn: AbsoluteFile) =
  ## XXX: write a module to a file; slow mo'
  var fh: File
  #
  # we'll do something like this and try to optimize compression to a smaller
  # chunk size; then we can worry about streaming it back out through thaw...
  #
  #if not open(fh, $fn, fmWrite, bufSize = max(maxBufSize, byteSize(m))):
  if not open(fh, $fn, fmWrite):
    raise newException(IOError, "couldn't store $1 into $2" % [ $m.name, $fn ])
  else:
    try:
      write fh, compress(freeze m)
    finally:
      close fh

proc readOut*(fn: AbsoluteFile): Module =
  ## XXX: read a module from a file; slow mo'
  var fh: File
  if not open(fh, $fn, fmRead):
    raise newException(IOError, "couldn't read module from $1" % [ $fn ])
  else:
    try:
      result = thaw[Module] uncompress(readAll fh)
      # TODO: why record the name of the file in the file?
      #       i will overwrite it here and if you're here
      #       to fix a bug, you can remove it with a comment.
      result.file = fn
    finally:
      close fh
