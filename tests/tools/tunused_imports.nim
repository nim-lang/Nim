discard """
  cmd: '''nim c --hint[Processing]:off $file'''
  nimout: '''
tunused_imports.nim(11, 10) Warning: BEGIN [User]
tunused_imports.nim(27, 10) Warning: END [User]
tunused_imports.nim(25, 8) Warning: imported and not used: 'strutils' [UnusedImport]
'''
  action: "compile"
"""

{.warning: "BEGIN".}

import net, dontmentionme

echo AF_UNIX

import macros
# bug #11809
macro bar(): untyped =
  template baz() = discard
  result = getAst(baz())

bar()

import strutils

{.warning: "END".}
