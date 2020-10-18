discard """
valgrind: true
cmd: "nim $target --gc:arc $options $file"
exitcode: 0
"""

# unlike tleak_arc_useMalloc.nim, tleak_arc_noUseMalloc.nim is powerless to
# detect the memory leak because malloc is not used
discard alloc(1)
