discard """
  cmd: "nim check -b:js $file"
  action: "compile"
"""

# bug #17286

import std/compilesettings

static:
  doAssert querySetting(backend) == "js"
  doAssert defined(js)
  doAssert not defined(c)

import random
randomize()