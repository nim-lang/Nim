discard """
  output: "ok"
"""

# checks that this is joinable
# checks that megatest allows duplicate names, see also `tests/misc/tjoinable.nim`
doAssert defined(testing)
doAssert defined(nimMegatest)
echo "ok" # intentional to make sure this doesn't prevent `isJoinableSpec`
