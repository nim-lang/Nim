discard """
  errormsg: "'let' symbol requires an initialization"
  line: "7"
"""

# Test that this still works when not annotated with importc
let test: cint
echo test
