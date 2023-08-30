discard """
output: '''
bye
hi
'''
  
"""

#infers void auto
import std/sugar

proc sup(fn: proc(a: string)) = fn("bye")
sup(proc(a:auto): auto = echo "bye")
sup(x => echo "hi")