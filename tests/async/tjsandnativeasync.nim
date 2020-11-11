discard """
  output: '''hi
bye'''
"""

import async, times
when defined(js):
    proc sleepAsync(t: int): Future[void] =
        var promise = newPromise() do(resolve: proc()):
            {.emit: """
            setTimeout(function(){
                `resolve`();
            }, `t`);
            """.}
        result = promise
else:
    from asyncdispatch import sleepAsync, waitFor

proc foo() {.async.} =
    echo "hi"
    var s = epochTime()
    await sleepAsync(200)
    var e = epochTime()
    doAssert(e - s > 0.1)
    echo "bye"

when defined(js):
    discard foo()
else:
    waitFor foo()
