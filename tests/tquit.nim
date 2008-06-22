# Test the new beforeQuit variable: 

import
  io

proc myExit() {.noconv.} = 
  write(stdout, "just exiting...\n")

addQuitProc(myExit)
