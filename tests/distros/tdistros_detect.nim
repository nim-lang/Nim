import distros

discard """
  exitcode: 0
  output: ""
"""

when defined(windows):
    doAssert detectOs(Windows) == true
    doAssert detectOs(Linux) == false
    doAssert detectOs(MacOSX) == false

when defined(linux):
    doAssert detectOs(Linux) == true
    doAssert detectOs(Windows) == false
    doAssert detectOs(MacOSX) == false

when defined(macosx):
    doAssert detectOs(MacOSX) == true
    doAssert detectOs(Windows) == false
    doAssert detectOs(Linux) == false
