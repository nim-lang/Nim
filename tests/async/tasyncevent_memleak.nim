discard """
  cmd: "nim c -r --threads:on --mm:orc $file"
  output: "0"
"""

when defined(windows):
  import asyncdispatch

  let before = getOccupiedSharedMem()

  block:
    let ev = newAsyncEvent()
    addEvent(ev) do (fd: AsyncFD) -> bool:
      true
    ev.close()

  block:
    let ev = newAsyncEvent()
    addEvent(ev) do (fd: AsyncFD) -> bool:
      true
    ev.unregister()
    ev.close()

  setGlobalDispatcher(nil)
  echo getOccupiedSharedMem() - before
else:
  echo 0
