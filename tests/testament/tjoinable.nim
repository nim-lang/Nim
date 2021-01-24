discard """
  output: "ok"
"""

# checks that this is joinable
doAssert defined(testing)
doAssert defined(nimMegatest)
echo "ok" # intentional to make sure this doesn't prevent `isJoinableSpec`
