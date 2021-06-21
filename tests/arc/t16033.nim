discard """
  targets: "c js"
  matrix: "--gc:arc"
"""

# bug #16033
when defined js:
  doAssert not compileOption("gc", "arc")
else:
  doAssert compileOption("gc", "arc")
