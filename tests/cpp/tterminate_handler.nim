discard """
  targets: "cpp"
  outputsub: "Error: unhandled cpp exception: [int]"
  exitcode: 1
"""
type Crap {.importcpp: "int".} = object

var c: Crap
raise c