discard """
valgrind: true
cmd: "nim $target --gc:orc -d:useMalloc $options $file"
exitcode: 1
outputsub: "   definitely lost: 7 bytes in 2 blocks"
"""

discard alloc(3)
discard alloc(4)
