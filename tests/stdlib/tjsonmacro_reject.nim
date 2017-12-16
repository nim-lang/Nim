discard """
  file: "tjsonmacro_reject.nim"
  line: 11
  errormsg: "Use a named tuple instead of: (string, float)"
"""

import json

type
  Car = object
    engine: (string, float)
    model: string

let j = """
  {"engine": {"name": "V8", "capacity": 5.5}, model: "Skyline"}
"""
let parsed = parseJson(j)
echo(to(parsed, Car))