discard """
  output: '''
@[1, 2, 3, 4]
123
'''
"""

# bug #5314, bug #6626

import asyncdispatch

proc bar(i: int): Future[int] {.async.} =
    await sleepAsync(2)
    result = i

proc foo(): Future[seq[int]] {.async.} =
    await sleepAsync(2)
    result = @[1, 2, await bar(3), 4] # <--- The bug is here

proc foo2() {.async.} =
    await sleepAsync(2)
    echo(await bar(1), await bar(2), await bar(3))

echo waitFor foo()
waitFor foo2()
