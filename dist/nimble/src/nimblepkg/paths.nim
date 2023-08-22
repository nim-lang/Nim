# Copyright (C) Dominik Picheta. All rights reserved.
# BSD License. Look at license.txt for more info.

## This module implements operations with file system paths in a way independent
## of weather the path is absolute or relative to the current directory.

import os, json, hashes

type Path* = distinct string

converter toPath*(path: string): Path = Path(path)

proc `%`*(path: Path): JsonNode {.borrow.}
proc `$`*(path: Path): string {.borrow.}

proc isAbsolute*(path: Path): bool {.borrow.}
proc splitFile*(path: Path): tuple[dir, name, ext: Path] {.borrow.}
proc splitPath*(path: Path): tuple[head, tail: Path] {.borrow.}
proc normalizedPath*(path: Path): Path {.borrow.}
proc dirExists*(dirname: Path): bool {.borrow.}
proc fileExists*(filename: Path): bool {.borrow.}
proc parseFile*(filename: Path): JsonNode {.borrow.}
proc `/`*(head, tail: Path): Path {.borrow.}
proc writeFile*(filename: Path, content: string) {.borrow.}
proc len*(path: Path): int {.borrow.}
proc isRootDir*(path: Path): bool {.borrow.}
proc parentDir*(path: Path): Path {.borrow.}
proc quoteShell*(s: Path): Path {.borrow.}

proc hash*(path: Path): Hash = hash(absolutePath(string(path)))

proc `==`*(lhs, rhs: Path): bool =
  absolutePath(string(lhs)) == absolutePath(string(rhs))

when isMainModule:
  import unittest

  const testDir: Path = "some/relative/path/"
  let absolutePathToTestDir: Path = getCurrentDir() / testDir

  test "hashing":
    check hash(testDir) == hash(absolutePathToTestDir)

  test "equals":
    check testDir == absolutePathToTestDir
