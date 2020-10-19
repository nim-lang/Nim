discard """
valgrind: true
cmd: "nim $target --gc:arc -d:useMalloc $options $file"
disabled: "windows"
disabled: "macosx"
disabled: "32bit"
"""

# test that a memory leak is caught by valgrind
discard alloc(1)
