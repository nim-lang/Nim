import
  ".." / [ pathutils ],
  packed_ast, frosty, supersnappy,
  std / [ strutils, streams, hashes ]

##[

read/write modules to/from disk

]##

const
  version =
    when defined(release): NimVersion else: CompileDate & CompileTime

proc writeIn*(m: Module; fn: AbsoluteFile) =
  ## XXX: write a module to a file; slow mo' because it doesn't use stream
  var stream = newFileStream($fn, fmWrite)

  try:
    freeze(version, stream)
    freeze(hash(m), stream)
    write(stream, compress(freeze m))
  finally:
    close stream

proc readOut*(fn: AbsoluteFile): Module =
  ## XXX: read a module from a file; slow mo' because it doesn't use stream
  var stream = newFileStream($fn, fmRead)
  try:
    var ver: string
    var sanity: Hash
    thaw[string](stream, ver)
    if ver != version:
      raise newException(ValueError,
        "version $1 doesn't match $2" % [ $ver, $version ])
    else:
      thaw[Hash](stream, sanity)
      result = thaw[Module] uncompress(readAll stream)
      if hash(result) != sanity:
        raise newException(ValueError, "hashes don't match")
  finally:
    close stream
