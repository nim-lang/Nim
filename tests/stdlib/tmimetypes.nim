discard """
  targets: "c js"
"""

import std/mimetypes
template main() =
  var m = newMimetypes()
  doAssert m.getMimetype("mp4") == "video/mp4"
  # see also `runnableExamples`.
  # xxx we should have a way to avoid duplicating code between runnableExamples and tests

static: main()
main()
