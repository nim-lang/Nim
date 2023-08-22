discard """
  output: '''5'''
joinable: false
"""

import mdontleak
# bug #19213

let a = 5'u32
echo a
