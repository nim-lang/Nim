discard """
output: '''
just exiting...
'''
joinable: false
"""

# Test `addQuitProc` (now deprecated by `addExitProc`)

proc myExit() {.noconv.} =
  write(stdout, "just exiting...\n")

{.push warning[deprecated]: off.}
addQuitProc(myExit)
{.pop.}
