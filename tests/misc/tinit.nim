discard """
  output: "Hello from module! Hello from main module!"
"""
# Test the new init section in modules

import minit

write(stdout, "Hello from main module!\n")
#OUT Hello from module! Hello from main module!
