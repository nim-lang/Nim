#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides access to the inferred .raises effects
## for Nim's macro system.

import macros

proc getRaisesListImpl(n: NimNode): NimNode = discard "see compiler/vmops.nim"

proc getRaisesList*(call: NimNode): NimNode =
  expectKind call, nnkCallKinds
  result = getRaisesListImpl(call[0])
