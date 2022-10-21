import std/private/osseps
export osseps

from std/private/ospaths2 {.all.} import joinPathImpl, joinPath, splitPath,
                                      ReadDirEffect, WriteDirEffect,
                                      isAbsolute, relativePath, normalizedPath,
                                      normalizePathEnd, isRelativeTo, parentDir,
                                      tailDir, isRootDir, parentDirs, `/../`,
                                      searchExtPos, extractFilename, lastPathPart,
                                      changeFileExt, addFileExt, cmpPaths,
                                      unixToNativePath, absolutePath, normalizeExe
export ReadDirEffect, WriteDirEffect

type
  Path* = distinct string


func joinPath*(head, tail: Path): Path {.inline.} =
  ## Joins two directory names to one.
  ##
  ## returns normalized path concatenation of `head` and `tail`, preserving
  ## whether or not `tail` has a trailing slash (or, if tail if empty, whether
  ## head has one).
  ##
  ## See also:
  ## * `joinPath(parts: varargs[Path]) proc`_
  ## * `/ proc`_
  ## * `splitPath proc`_
  ## * `uri.combine proc <uri.html#combine,Uri,Uri>`_
  ## * `uri./ proc <uri.html#/,Uri,string>`_
  result = Path(joinPath(head.string, tail.string))

func joinPath*(parts: varargs[Path]): Path =
  ## The same as `joinPath(head, tail) proc`_,
  ## but works with any number of directory parts.
  ##
  ## You need to pass at least one element or the proc
  ## will assert in debug builds and crash on release builds.
  ##
  ## See also:
  ## * `joinPath(head, tail) proc`_
  ## * `/ proc`_
  ## * `/../ proc`_
  ## * `splitPath proc`_
  var estimatedLen = 0
  for p in parts: estimatedLen += p.string.len
  var res = newStringOfCap(estimatedLen)
  var state = 0
  for i in 0..high(parts):
    joinPathImpl(res, state, parts[i].string)
  result = Path(res)

func `/`*(head, tail: Path): Path {.inline.} =
  ## The same as `joinPath(head, tail) proc`_.
  ##
  ## See also:
  ## * `/../ proc`_
  ## * `joinPath(head, tail) proc`_
  ## * `joinPath(parts: varargs[Path]) proc`_
  ## * `splitPath proc`_
  ## * `uri.combine proc <uri.html#combine,Uri,Uri>`_
  ## * `uri./ proc <uri.html#/,Uri,string>`_
  joinPath(head, tail)

func splitPath*(path: Path): tuple[head, tail: Path] {.inline.} =
  ## Splits a directory into `(head, tail)` tuple, so that
  ## ``head / tail == path`` (except for edge cases like "/usr").
  ##
  ## See also:
  ## * `joinPath(head, tail) proc`_
  ## * `joinPath(parts: varargs[Path]) proc`_
  ## * `/ proc`_
  ## * `/../ proc`_
  ## * `relativePath proc`_
  let res = splitPath(path.string)
  result = (Path(res.head), Path(res.tail))

func isAbsolute*(path: Path): bool {.inline, raises: [].} =
  ## Checks whether a given `path` is absolute.
  ##
  ## On Windows, network paths are considered absolute too.
  result = isAbsolute(path.string)

proc relativePath*(path, base: Path, sep = DirSep): Path {.inline.} =
  ## Converts `path` to a path relative to `base`.
  ##
  ## The `sep` (default: DirSep_) is used for the path normalizations,
  ## this can be useful to ensure the relative path only contains `'/'`
  ## so that it can be used for URL constructions.
  ##
  ## On Windows, if a root of `path` and a root of `base` are different,
  ## returns `path` as is because it is impossible to make a relative path.
  ## That means an absolute path can be returned.
  ##
  ## See also:
  ## * `splitPath proc`_
  ## * `parentDir proc`_
  ## * `tailDir proc`_
  result = Path(relativePath(path.string, base.string, sep))

proc isRelativeTo*(path: Path, base: Path): bool {.inline.} =
  ## Returns true if `path` is relative to `base`.
  result = isRelativeTo(path.string, base.string)

proc normalizedPath*(path: Path): Path {.inline, tags: [].} =
  ## Returns a normalized path for the current OS.
  ##
  ## See also:
  ## * `absolutePath proc`_
  ## * `normalizePath proc`_ for the in-place version
  result = Path(normalizedPath(path.string))

proc normalizePathEnd*(path: var Path, trailingSep = false) {.borrow.}

proc normalizePathEnd*(path: Path, trailingSep = false): Path {.borrow.}

func parentDir*(path: Path): Path {.inline.} =
  ## Returns the parent directory of `path`.
  ##
  ## This is similar to ``splitPath(path).head`` when ``path`` doesn't end
  ## in a dir separator, but also takes care of path normalizations.
  ## The remainder can be obtained with `lastPathPart(path) proc`_.
  ##
  ## See also:
  ## * `relativePath proc`_
  ## * `splitPath proc`_
  ## * `tailDir proc`_
  ## * `parentDirs iterator`_
  result = Path(parentDir(path.string))

func tailDir*(path: Path): Path {.inline.} =
  ## Returns the tail part of `path`.
  ##
  ## See also:
  ## * `relativePath proc`_
  ## * `splitPath proc`_
  ## * `parentDir proc`_
  result = Path(tailDir(path.string))

func isRootDir*(path: Path): bool {.inline.} =
  ## Checks whether a given `path` is a root directory.
  result = isRootDir(path.string)

iterator parentDirs*(path: Path, fromRoot=false, inclusive=true): Path =
  ## Walks over all parent directories of a given `path`.
  ##
  ## If `fromRoot` is true (default: false), the traversal will start from
  ## the file system root directory.
  ## If `inclusive` is true (default), the original argument will be included
  ## in the traversal.
  ##
  ## Relative paths won't be expanded by this iterator. Instead, it will traverse
  ## only the directories appearing in the relative path.
  ##
  ## See also:
  ## * `parentDir proc`_
  ##
  for p in parentDirs(path.string, fromRoot, inclusive):
    yield Path(p)

func `/../`*(head, tail: Path): Path {.inline.} =
  ## The same as ``parentDir(head) / tail``, unless there is no parent
  ## directory. Then ``head / tail`` is performed instead.
  ##
  ## See also:
  ## * `/ proc`_
  ## * `parentDir proc`_
  Path(`/../`(head.string, tail.string))

proc searchExtPos*(path: Path): int {.inline.} =
  ## Returns index of the `'.'` char in `path` if it signifies the beginning
  ## of extension. Returns -1 otherwise.
  ##
  ## See also:
  ## * `splitFile proc`_
  ## * `extractFilename proc`_
  ## * `lastPathPart proc`_
  ## * `changeFileExt proc`_
  ## * `addFileExt proc`_
  result = searchExtPos(path.string)

func extractFilename*(path: Path): Path {.inline.} =
  ## Extracts the filename of a given `path`.
  ##
  ## This is the same as ``name & ext`` from `splitFile(path) proc`_.
  ##
  ## See also:
  ## * `searchExtPos proc`_
  ## * `splitFile proc`_
  ## * `lastPathPart proc`_
  ## * `changeFileExt proc`_
  ## * `addFileExt proc`_
  result = Path(extractFilename(path.string))

func lastPathPart*(path: Path): Path {.inline.} =
  ## Like `extractFilename proc`_, but ignores
  ## trailing dir separator; aka: `baseName`:idx: in some other languages.
  ##
  ## See also:
  ## * `searchExtPos proc`_
  ## * `splitFile proc`_
  ## * `extractFilename proc`_
  ## * `changeFileExt proc`_
  ## * `addFileExt proc`_
  result = Path(lastPathPart(path.string))

func changeFileExt*(filename, ext: Path): Path {.inline.} =
  ## Changes the file extension to `ext`.
  ##
  ## If the `filename` has no extension, `ext` will be added.
  ## If `ext` == "" then any extension is removed.
  ##
  ## `Ext` should be given without the leading `'.'`, because some
  ## filesystems may use a different character. (Although I know
  ## of none such beast.)
  ##
  ## See also:
  ## * `searchExtPos proc`_
  ## * `splitFile proc`_
  ## * `extractFilename proc`_
  ## * `lastPathPart proc`_
  ## * `addFileExt proc`_
  result = Path(changeFileExt(filename.string, ext.string))

func addFileExt*(filename, ext: Path): Path {.inline.} =
  ## Adds the file extension `ext` to `filename`, unless
  ## `filename` already has an extension.
  ##
  ## `Ext` should be given without the leading `'.'`, because some
  ## filesystems may use a different character.
  ## (Although I know of none such beast.)
  ##
  ## See also:
  ## * `searchExtPos proc`_
  ## * `splitFile proc`_
  ## * `extractFilename proc`_
  ## * `lastPathPart proc`_
  ## * `changeFileExt proc`_
  result = Path(addFileExt(filename.string, ext.string))

func cmpPaths*(pathA, pathB: Path): int {.inline.} =
  ## Compares two paths.
  ##
  ## On a case-sensitive filesystem this is done
  ## case-sensitively otherwise case-insensitively. Returns:
  ##
  ## | 0 if pathA == pathB
  ## | < 0 if pathA < pathB
  ## | > 0 if pathA > pathB
  result = cmpPaths(pathA.string, pathB.string)

func unixToNativePath*(path: Path, drive=Path("")): Path {.inline.} =
  ## Converts an UNIX-like path to a native one.
  ##
  ## On an UNIX system this does nothing. Else it converts
  ## `'/'`, `'.'`, `'..'` to the appropriate things.
  ##
  ## On systems with a concept of "drives", `drive` is used to determine
  ## which drive label to use during absolute path conversion.
  ## `drive` defaults to the drive of the current working directory, and is
  ## ignored on systems that do not have a concept of "drives".
  result = Path(unixToNativePath(path.string, drive.string))

proc getCurrentDir*(): Path {.inline, tags: [].} =
  ## Returns the `current working directory`:idx: i.e. where the built
  ## binary is run.
  ##
  ## So the path returned by this proc is determined at run time.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getConfigDir proc`_
  ## * `getTempDir proc`_
  ## * `setCurrentDir proc`_
  ## * `currentSourcePath template <system.html#currentSourcePath.t>`_
  ## * `getProjectPath proc <macros.html#getProjectPath>`_
  result = Path(ospaths2.getCurrentDir())

proc setCurrentDir*(newDir: Path) {.inline, tags: [].} =
  ## Sets the `current working directory`:idx:; `OSError`
  ## is raised if `newDir` cannot been set.
  ##
  ## See also:
  ## * `getHomeDir proc`_
  ## * `getConfigDir proc`_
  ## * `getTempDir proc`_
  ## * `getCurrentDir proc`_
  ospaths2.setCurrentDir(newDir.string)

proc normalizeExe*(file: var Path) {.borrow.}
