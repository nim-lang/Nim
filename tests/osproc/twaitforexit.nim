import std/[osproc, os, times]

block: # bug #5091
    when defined(linux):
        const filename = "false"
        var p = startProcess(filename, options = {poStdErrToStdOut, poUsePath})
        os.sleep(1000) # make sure process has exited already

        let atStart = getTime()
        const msWait = 2000

        try:
            discard waitForExit(p, msWait)
        except OSError:
            discard

        # check that we don't have to wait msWait milliseconds
        doAssert(getTime() <  atStart + milliseconds(msWait))