discard """
output: '''
@[]
'''
"""

# bug #16298

{.push warning[ProveInit]: on, warningAsError[ProveInit]:on .}
echo newSeqOfCap[tuple[a: var int]](1)
