
## This module provides access to the inferred .raises and .tags effects
## for Nim's macro system.

import macros

proc getRaisesListImpl(n: NimNode): NimNode = discard "see compiler/vmops.nim"

proc getRaisesList*(n: NimNode): NimNode =
  expectKind n, RoutineNodes
  result = getRaisesListImpl(n)



