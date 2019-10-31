discard """
cmd: "nim $target --threads:on $options $file"
output: '''
'''
"""

import sharedtables

var table: SharedTable[int, int]

init(table)
table[1] = 10
assert table.mget(1) == 10
assert table.mgetOrPut(3, 7) == 7
assert table.mgetOrPut(3, 99) == 7
