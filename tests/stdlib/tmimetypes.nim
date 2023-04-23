discard """
  matrix: "--mm:refc; --mm:orc"
  targets: "c js"
"""

import std/mimetypes
import std/assertions


template main() =
  var m = newMimetypes()
  doAssert m.getMimetype("mp4") == "video/mp4"
  doAssert m.getExt("application/json") == "json"
  m.register("foo", "baa")
  doAssert m.getMimetype("foo") == "baa"
  # see also `runnableExamples`.
  # xxx we should have a way to avoid duplicating code between runnableExamples and tests

static: main()
main()
