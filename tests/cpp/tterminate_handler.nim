discard """
  targets: "cpp"
  outputsub: "Error: unhandled unknown cpp exception"
  exitcode: 1
"""
type Crap {.importcpp: "int".} = object

var c: Crap
raise c