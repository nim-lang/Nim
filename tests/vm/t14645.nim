discard """
  output: "0"
"""

# bug #14645
import std/strformat
proc re(s: static string): string = s
proc p =
  const rx = re(&"")
  echo rx.len
p()
