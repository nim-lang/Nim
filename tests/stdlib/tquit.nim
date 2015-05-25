# Test the new beforeQuit variable: 

proc myExit() {.noconv.} = 
  write(stdout, "just exiting...\N")

addQuitProc(myExit)
