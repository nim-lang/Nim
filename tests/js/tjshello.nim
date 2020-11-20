discard """
  cmd: "nim $target $options --stackTrace:off --lineTrace:off $file"
  output: "Hello World"
  maxcodesize: 1134
  ccodecheck: "!@'function'"
"""

import jsconsole

console.log "Hello World"
