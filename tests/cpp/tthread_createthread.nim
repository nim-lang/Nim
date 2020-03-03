discard """
  targets: "cpp"
  cmd: "nim cpp --hints:on --threads:on $options $file"
"""

proc threadMain(a: int) {.thread.} =
    discard

proc main() =
    var thread: Thread[int]

    thread.createThread(threadMain, 0)
    thread.joinThreads()

main()
