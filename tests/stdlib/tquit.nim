discard """
output: '''
just exiting...
'''
joinable: false
"""

# Test `addQuitProc` (now deprecated by `addExitProc`)

import std/syncio

proc myExit() {.noconv.} =
  write(stdout, "just exiting...\n")

{.push warning[deprecated]: off.}
addQuitProc(myExit)
{.pop.}
