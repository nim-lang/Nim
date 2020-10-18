discard """
valgrind: true
cmd: "nim $target --gc:refc -d:useMalloc $options $file"
exitcode: 0
"""

# Valgrind cannot detect this leak even if malloc is used because --gc:refc
discard alloc(1)
