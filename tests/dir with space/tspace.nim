discard """
output: "Successful"
"""
# Test for the compiler to be able to compile a Nim file with spaces in the directory name.
# Also test if import of a directory with a space works.

import "more spaces" / mspace

assert tenTimes(5) == 50
echo("Successful")
