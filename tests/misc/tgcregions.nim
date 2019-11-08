discard """
cmd: "nim c --gc:regions $file"
"""

# issue #12597
# it just tests that --gc:regions compiles. Nothing else.   :'(
