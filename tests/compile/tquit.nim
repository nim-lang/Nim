# Test the new beforeQuit variable: 

proc myExit() {.noconv.} = 
  write(stdout, "just exiting...\n")

addQuitProc(myExit)
