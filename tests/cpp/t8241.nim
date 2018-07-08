discard """
  targets: "cpp"
  action: "compile"
"""

proc foo(): cstring {.importcpp: "", dynlib: "".}
echo foo()
