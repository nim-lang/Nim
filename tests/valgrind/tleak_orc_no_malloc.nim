discard """
valgrind: true
cmd: "nim $target --gc:orc $options $file"
exitcode: 0
"""

# unlike tleak_orc_useMalloc.nim, tleak_orc_noUseMalloc.nim is powerless to
# detect the memory leak because malloc is not used
discard alloc(1)
