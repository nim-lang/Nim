discard """
output:
ok
"""

type
  Meters = distinct float
  Feet = distinct float

converter toMeters(f: Feet): Meters =
  Meters(float(f) * 0.3048)

proc showMeters(m: Meters) =
  echo "ok"

showMeters(Feet(10.0))
