discard """
  joinable: false
"""

import std/[assertions, os, tempfiles]
import compiler/[options, pathcache, pathutils]

let originalDir = getCurrentDir()
let dir = createTempDir("nim_pathcache_", "")
let left = dir / "left"
let right = dir / "right"

try:
  createDir(left)
  createDir(right)
  writeFile(left / "same.nim", "discard 1")
  writeFile(right / "same.nim", "discard 2")

  block current_directory_snapshot:
    setCurrentDir(left)
    var cache: PathCache
    doAssert cache.getCurrentDir() == getCurrentDir()
    doAssert cache.expandFilename("same.nim") == expandFilename(left / "same.nim")
    setCurrentDir(right)
    doAssert cache.getCurrentDir() == expandFilename(left)
    cache.reset()
    doAssert cache.getCurrentDir() == getCurrentDir()
    doAssert cache.expandFilename("same.nim") == expandFilename(right / "same.nim")

  block missing_files_are_not_cached:
    var cache: PathCache
    let generated = dir / "generated.nim"
    doAssertRaises(OSError):
      discard cache.expandFilename(generated)
    writeFile(generated, "discard")
    doAssert cache.expandFilename(generated) == expandFilename(generated)

  block relative_path_compatibility:
    var cache: PathCache
    for (path, base) in [
      ("same.nim", right), (right / "same.nim", ""),
      (right / "same.nim", "."), (right / "same.nim", ".."),
      ("../same.nim", "a/b"), ("a/b", "a/b"), ("", "a"), ("", right)]:
      doAssert cache.relativePath(path, base) == relativePath(path, base)
      doAssert cache.relativePath(path, base, '/') == relativePath(path, base, '/')

  when defined(posix):
    block symlinks_and_parent_components:
      createDir(dir / "actual" / "inner")
      writeFile(dir / "actual" / "target.nim", "discard 3")
      writeFile(dir / "target.nim", "discard 4")
      createSymlink(dir / "actual" / "inner", dir / "alias")
      # Do not lexically collapse '..' before resolving the directory symlink.
      let path = dir & "/alias/../target.nim"
      var cache: PathCache
      doAssert cache.expandFilename(path) == expandFilename(dir / "actual" / "target.nim")
      doAssert cache.expandFilename(path) == expandFilename(path)

    block canonical_snapshot_reset:
      let alias = dir / "source.nim"
      createSymlink(left / "same.nim", alias)
      var cache: PathCache
      let first = cache.expandFilename(alias)
      removeFile(alias)
      createSymlink(right / "same.nim", alias)
      doAssert cache.expandFilename(alias) == first
      cache.reset()
      doAssert cache.expandFilename(alias) == expandFilename(right / "same.nim")

  block config_and_ide_use_live_paths:
    let conf = newConfigRef()
    conf.cmd = cmdCompileToC
    setCurrentDir(left)
    doAssert conf.getCurrentDir() == getCurrentDir()
    conf.globalOptions.incl optWithinConfigSystem
    setCurrentDir(right)
    doAssert conf.getCurrentDir() == getCurrentDir()
    doAssert conf.canonicalizePath(AbsoluteFile"same.nim") ==
      AbsoluteFile(expandFilename(right / "same.nim"))
    conf.globalOptions.excl optWithinConfigSystem
    conf.resetPathCache()
    doAssert conf.getCurrentDir() == getCurrentDir()
    conf.ideActive = true
    setCurrentDir(left)
    doAssert conf.getCurrentDir() == getCurrentDir()
    doAssert conf.canonicalizePath(AbsoluteFile"same.nim") ==
      AbsoluteFile(expandFilename(left / "same.nim"))

  block relative_file_info_paths:
    let conf = newConfigRef()
    conf.cmd = cmdCompileToC
    doAssert conf.relativeTo(AbsoluteFile"same.nim", AbsoluteDir right).string ==
      relativePath("same.nim", right)
    doAssert conf.relativeTo(AbsoluteFile(left / "same.nim"), AbsoluteDir"").string ==
      relativePath(left / "same.nim", "")

  block prefix_override:
    let conf = newConfigRef()
    let prefix = conf.getPrefixDir()
    doAssert conf.getPrefixDir() == prefix
    conf.prefixDir = AbsoluteDir dir
    doAssert conf.getPrefixDir() == AbsoluteDir dir
finally:
  setCurrentDir(originalDir)
  removeDir(dir)
