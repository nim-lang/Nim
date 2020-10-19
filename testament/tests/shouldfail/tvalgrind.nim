discard """
valgrind: true
cmd: "nim $target --gc:arc -d:useMalloc $options $file"
disabled: "freebsd"
disabled: "macosx"
disabled: "openbsd"
disabled: "windows"
disabled: "32bit"
"""

# test that a memory leak is caught by valgrind
discard alloc(1)
