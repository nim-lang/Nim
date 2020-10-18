discard """
valgrind: true
cmd: "nim $target --gc:arc -d:useMalloc $options $file"
"""

# test that a memory leak is caught by valgrind
discard alloc(1)
