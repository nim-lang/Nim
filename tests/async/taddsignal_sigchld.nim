discard """
  output: '''
code: 3
output: hello
SIGCHLD seen: true
'''
  disabled: "windows"
"""

# bug #25649: watching SIGCHLD with `addSignal` must not change how children
# are reaped. On kqueue the watched signal used to be set to SIG_IGN, and an
# ignored SIGCHLD makes the kernel reap every child by itself: `waitpid` then
# fails and `execCmdEx` never returned.

import std/[asyncdispatch, osproc, posix, strutils]

# The bug made `execCmdEx` loop forever; end the test instead of hanging.
discard alarm(30)

var seen = false
addSignal(SIGCHLD, proc (fd: AsyncFD): bool =
  seen = true
  true)

let (output, code) = execCmdEx("/bin/sh -c 'echo hello; exit 3'")
echo "code: ", code
echo "output: ", output.strip()

for _ in 0 ..< 50:
  if seen: break
  poll(100)
echo "SIGCHLD seen: ", seen
