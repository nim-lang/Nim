discard """
  errormsg: "must be overridden for widget type"
  line: 15
"""

# Test for improved error messages when using {.error.} pragma on methods
# The error should show the call site and include the receiver type

type
  Widget = ref object of RootObj
  Button = ref object of Widget

method getTypeName(w: Widget): string {.error: "must be overridden for widget type".}

proc test() =
  let b = Button()
  echo b.getTypeName()  # Error should point here and mention Button type

test()
