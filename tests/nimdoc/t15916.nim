discard """
cmd: "nim doc --hints:off $file"
action: "compile"
joinable: false
"""

type
  Test* = object
    id: int

proc initTest*(id: int): Test =
  result.id = id

proc hello*() =
  runnableExamples:
    discard
