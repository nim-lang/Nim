discard """
output: '''hallo'''
joinable: false
"""

# bug #9978, #9994
var x: DefinedInB

echo "hi".replace("i", "allo")
