discard """
  output: "done markerproc regression"
"""

type
  Version* = distinct string
  Special* = distinct string

  VersionRangeEnum* = enum
    verLater, # > V
    verEarlier, # < V
    verEqLater, # >= V -- Equal or later
    verEqEarlier, # <= V -- Equal or earlier
    verIntersect, # > V & < V
    verEq, # V
    verAny, # *
    verSpecial # #head

  VersionRange* = ref VersionRangeObj
  VersionRangeObj = object
    case kind*: VersionRangeEnum
    of verLater, verEarlier, verEqLater, verEqEarlier, verEq:
      ver*: Version
    of verSpecial:
      spe*: Special
    of verIntersect:
      verILeft, verIRight: VersionRange
    of verAny:
      nil

proc foo(x: string): VersionRange =
  new(result)
  result.kind = verEq
  result.ver = Version(x)

proc main =
  var a: array[500, VersionRange]
  for i in 0 ..< 500:
    a[i] = foo($i & "some longer text here " & $i)
  GC_fullcollect()
  for i in 0 ..< 500:
    let expected = $i & "some longer text here " & $i
    if a[i].ver.string != expected:
      quit "bug!"
  echo "done markerproc regression"

main()
