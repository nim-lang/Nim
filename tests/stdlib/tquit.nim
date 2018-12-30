discard """
output: '''
just exiting...
'''
joinable: false
"""

# Test the new beforeQuit variable:

proc myExit() {.noconv.} =
  write(stdout, "just exiting...\n")

addQuitProc(myExit)
