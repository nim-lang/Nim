#
#
#           The Nim Compiler
#        (c) Copyright 2020 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#
import
  ".." / [ pathutils, options, msgs ],
  packed_ast, frosty, supersnappy,
  std / [ strutils, streams, hashes, os ]

import std/options as stdoptions
from ".." / ccgutils import mangle  # for filename mangling

##[

read/write modules to/from disk

]##

type
  MetaReply = object     ## result of a metadata query of a rod file
    ok: bool
    msg: string
    version: string
    hash: Hash

const
  version =
    when defined(release): NimVersion else: CompileDate & CompileTime

template config(m: Module): ConfigRef = m.ast.sh.config

proc writeModuleInto(m: Module; fn: AbsoluteFile; value = hash(m)) =
  var stream = newFileStream($fn, fmWrite)
  try:
    freeze(version, stream)
    freeze(value, stream)
    # try to reduce some buffer churn
    freeze(compress(freeze m), stream)
  finally:
    close stream
    writeFile("/tmp/module.rod", freeze m)
    echo "uncompressed module: ", getFileSize("/tmp/module.rod")
    writeFile("/tmp/config.rod", freeze m.ast.sh.config)
    echo "uncompressed config: ", getFileSize("/tmp/config.rod")
    var x = thaw[ConfigRef] readFile"/tmp/config.rod"
    assert hash(x) == hash(m.ast.sh.config)
    var y = thaw[Module] readFile"/tmp/module.rod"
    assert hash(y) == hash(m)

proc queryRodMeta(stream: Stream): MetaReply {.raises: [].} =
  ## query a rod file stream to see if it is worth attempting to use
  try:
    setPosition(stream, 0)
    thaw[string](stream, result.version)
    if result.version != version:
      result.msg = "version `$1` doesn't match `$2`" % [ $result.version,
                                                         $version ]
    else:
      thaw[Hash](stream, result.hash)
      result.ok = true
  except CatchableError as e:
    result.msg = e.msg

proc queryRodMeta(fn: AbsoluteFile): MetaReply =
  ## query a rod file to see if it is worth attempting to use
  if not fileExists fn:
    result.msg = $fn & ": file not found"
  else:
    try:
      var stream = newFileStream($fn, fmRead)
      try:
        result = queryRodMeta(stream)
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

proc tryReadModuleNamed*(config: ConfigRef; name: string): Option[Module] =
  ## populated option if reading the module was successful
  let fn = composeFilename(config, name)
  if fileExists fn:
    echo "📖", $fn
    var stream = newFileStream($fn, fmRead)
    try:
      let reply = queryRodMeta stream
      if reply.ok:
        # try to reduce some buffer churn
        var snap = newStringOfCap(getFileSize $fn)
        thaw[string](stream, snap)

        let m = thaw[Module] uncompress(snap)
        if hash(config) != hash(m.config):
          # NOTE: we just bail if the configs don't hash equivalently
          return
        if hash(m) != reply.hash:
          internalError(config, $fn & ": hashes don't match")
        result = some m
      else:
        when not defined(release):
          echo reply.msg
    except ThawError as e:
      handleFileError(config, fn, e)
    except SnappyError as e:
      handleFileError(config, fn, e)
    finally:
      close stream

proc tryWriteModule*(m: Module): bool =
  ## true if we were able to write the module successfully
  let fn = composeFilename(m.config, m.name)
  let reply = queryRodMeta fn
  let value = hash(m)
  when not defined(release):
    if reply.ok:
      if reply.hash == value:
        internalError(m.config, "gratuitous module write")
  m.writeModuleInto(fn, value = value)  # pre-supply the hash
  result = true
