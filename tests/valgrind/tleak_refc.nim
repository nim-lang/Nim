discard """
valgrind: true
cmd: "nim $target --gc:refc -d:useMalloc $options $file"
exitcode: 0
disabled: "windows"
disabled: "macosx"
disabled: "32bit"
"""

# Valgrind cannot detect this leak even if malloc is used because --gc:refc
discard alloc(1)
