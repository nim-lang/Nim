discard """
disabled: "windows"
"""

# This tests an asm statement that contains quote characters.
# MSVC does not have inline assembly, therefore it is diabled there.
asm """
string_txt:
    .incbin "../testdata/string.txt"
"""

# Ensure the asm statement isn't ignored or optimized away.
const data = slurp("../testdata/string.txt")
var string_txt {.importc: "string_txt".}: array[len(data), char]
for i in 0 ..< data.len:
  doAssert(data[i] == string_txt[i])
