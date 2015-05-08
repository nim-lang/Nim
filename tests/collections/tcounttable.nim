discard """
  output: "And we get here"
"""

# bug #2625

const s_len = 32

import tables
var substr_counts: CountTable[string] = initCountTable[string]()
var my_string = "Hello, this is sadly broken for strings over 64 characters. Note that it *does* appear to work for short strings."
for i in 0..(my_string.len - s_len):
  let s = my_string[i..i+s_len-1]
  substr_counts[s] = 1
  # substr_counts[s] = substr_counts[s] + 1  # Also breaks, + 2 as well, etc.
  # substr_counts.inc(s)  # This works
  #echo "Iteration ", i

echo "And we get here"
