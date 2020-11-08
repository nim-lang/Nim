discard """
  outputsub: "index 2 not in 0 .. 0 [IndexDefect]"
  exitcode: 1
  cmd: "nim c --gc:arc --exceptions:setjmp $file"
"""

# bug #12961
# --gc:arc --exceptions:setjmp
let a = @[1]
echo a[2]

