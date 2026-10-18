discard """
  cmd: "nim $target --hints:on --define:useNimRtl $options $file"
  output: '''
thread 1 says hello
thread 2 says hello
main says hello'''
"""

# A program that uses nimrtl has nimrtl's allocator, which needs each thread
# to check out a memory region before its first allocation. The program did
# not do that for the threads it started, and the first allocation in such a
# thread crashed.

proc worker(n: int) {.thread.} =
  echo "thread ", n, " says hello"

var threads: array[2, Thread[int]]
for i in 0 .. 1:
  createThread(threads[i], worker, i + 1)
  joinThread(threads[i])
echo "main says hello"
