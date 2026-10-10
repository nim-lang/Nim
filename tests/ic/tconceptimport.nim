discard """
output: '''ok'''
"""

# Concept requirements live in the concept type's NIF body. Keep their AST
# structure when loading the concept in another module so concept matching can
# see and compare those requirements.
import mconceptsize

static:
  doAssert uint8 is Sized

echo "ok"
