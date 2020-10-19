discard """
valgrind: true
cmd: "nim $target --gc:arc -d:useMalloc $options $file"
exitcode: 1
outputsub: "   definitely lost: 7 bytes in 2 blocks"
disabled: "windows"
disabled: "macosx"
disabled: "32bit"
"""

discard alloc(3)
discard alloc(4)
