discard """
output: "i0"
"""

type
  Application = object
      config: void
      i: int
      f: void

proc printFields(rec: Application) =
  for k, v in fieldPairs(rec):
    echo k, v

var app: Application

printFields(app)
