discard """
  cmd: "nim c --app:console $file"
  action: "compile"
"""

import terminal

writeStyled("hello", {styleBright})
