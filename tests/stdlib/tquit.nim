discard """
output: '''
just exiting...
'''
joinable: false
"""

# Test `addQuitProc`

proc myExit() {.noconv.} =
  write(stdout, "just exiting...\n")

addQuitProc(myExit)
