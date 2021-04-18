discard """
  output: '''success'''
  cmd: "nim c --gc:orc -d:release $file"
"""

# bug #17170

when true:
  import asyncdispatch

  type
    Flags = ref object
      returnedEof, reading: bool

  proc dummy(): Future[string] {.async.} =
    result = "foobar"

  proc hello(s: Flags) {.async.} =
    let buf =
      try:
        await dummy()
      except CatchableError as exc:
        # When an exception happens here, the Bufferstream is effectively
        # broken and no more reads will be valid - for now, return EOF if it's
        # called again, though this is not completely true - EOF represents an
        # "orderly" shutdown and that's not what happened here..
        s.returnedEof = true
        raise exc
      finally:
        s.reading = false

  waitFor hello(Flags())
  echo "success"

