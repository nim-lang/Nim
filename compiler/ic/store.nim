#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import
  ".." / [ ast, pathutils, options, msgs ],
  packed_ast, frosty, supersnappy,
  std / [ strutils, streams, hashes, os ]

import std/options as stdoptions
from ".." / ccgutils import mangle  # for filename mangling

##[

read/write modules to/from disk

]##

type
  Header = object     ## result of a metadata query of a rod file
    ok: bool
    msg: string       # populated with any error message
    version: string   # rodfile version
    config: Hash      # hash of the writer's ConfigRef
    hash: Hash        # hash of the writer's PackedTree

const
  version =
    when defined(release): NimVersion else: CompileDate & " " & CompileTime

template config(m: Module): ConfigRef = m.ast.sh.config

proc rodFile*(conf: ConfigRef; m: PSym): AbsoluteFile =
  ## find the target rodfile of a given module
  result = AbsoluteFile toFullPath(conf, m.info.fileIndex)
  result = result.changeFileExt "rod"

proc writeModuleInto(m: Module; fn: AbsoluteFile; value = hash(m)) =
  ## write the module into the given rodfile path; the hash value
  ## allows us to save an extra computation of the hash
  let noSerializeSubstitute = m.ast.sh.config
  var stream = newFileStream($fn, fmWrite)
  m.ast.sh.config = nil
  try:
    # the following three values constitute the rodfile's "header"
    freeze(version, stream)
    freeze(hash noSerializeSubstitute, stream)   # XXX: cache config hash?
    freeze(value, stream)
    # try to reduce some buffer churn on the read
    freeze(compress(freeze m), stream)
  finally:
    m.ast.sh.config = noSerializeSubstitute
    close stream

proc readHeader(stream: Stream): Header {.raises: [].} =
  ## query a rod file stream to see if it is worth attempting to use
  try:
    setPosition(stream, 0)
    thaw(stream, result.version)
    if result.version != version:
      result.msg = "version `$1` doesn't match `$2`" % [ $result.version,
                                                         $version ]
    else:
      thaw(stream, result.config)
      thaw(stream, result.hash)
      result.ok = true
  except CatchableError as e:
    result.msg = e.msg

proc readHeader(fn: AbsoluteFile): Header =
  ## query a rod file to see if it is worth attempting to use
  if not fileExists fn:
    result.msg = $fn & ": file not found"
  else:
    try:
      var stream = newFileStream($fn, fmRead)
      try:
        result = readHeader stream
      finally:
        close stream
    except CatchableError as e:
      result.msg = e.msg

proc composeFilename(config: ConfigRef; name: string): AbsoluteFile =
  ## turn an arbitrary name into a .rod filename
  let dir = getNimcacheDir(config) / RelativeDir "rod"
  createDir dir
  result = dir / addFileExt(RelativeFile mangle(name), "rod")

template handleFileError(config: ConfigRef; fn: AbsoluteFile; e: typed) =
  ## handle some kind of error thrown up by a rod file
  when defined(release):
    removeFile fn
  else:
    internalError(config, $fn & ": " & e.msg)

proc tryReadModule*(config: ConfigRef; fn: AbsoluteFile): Option[Module] =
  ## populated option if reading the module was successful
  if not fileExists fn: return none(Module)
  echo "📖", $fn
  var stream = newFileStream($fn, fmRead)
  try:
    let reply = readHeader stream
    if reply.ok:
      if hash(config) != reply.config:
        # NOTE: we just bail if the configs don't hash equivalently
        return
      # try to reduce some buffer churn
      var snap = newStringOfCap(getFileSize $fn)
      thaw(stream, snap)
      var m = thaw[Module] uncompress(snap)
      if hash(m.ast) != reply.hash:
        internalError(config, $fn & ": hashes don't match")
      # we omitted the config during write, so we must now reinstall it
      m.ast.sh.config = config
      result = some m
    else:
      when not defined(release):
        echo reply.msg
  except CatchableError as e:
    handleFileError(config, fn, e)
  finally:
    close stream

proc tryReadModule*(config: ConfigRef; name: string): Option[Module] =
  ## let IC compose the filename
  let fn = composeFilename(config, name)
  result = tryReadModule(config, fn)

proc tryWriteModule*(m: Module; fn: AbsoluteFile): bool =
  ## true if we were able to write the module successfully
  let reply = readHeader fn
  let value = hash(m.ast)
  when not defined(release):
    if reply.ok:
      if reply.hash == value:
        internalError(m.config, "gratuitous module write")
  m.writeModuleInto(fn, value = value)  # pre-supply the hash
  result = true

proc tryWriteModule*(m: Module): bool =
  ## let IC compose the filename
  let fn = composeFilename(m.config, m.name)
  result = tryWriteModule(m, fn)
