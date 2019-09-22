discard """
output: '''
event triggered!
'''
"""

import asyncDispatch

let ev = newAsyncEvent()
addEvent(ev, proc(fd: AsyncFD): bool {.gcsafe.} = echo "event triggered!"; true)
ev.trigger()

drain()
