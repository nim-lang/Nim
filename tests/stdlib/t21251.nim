import std / [tables, sets, sharedtables]

var shared: SharedTable[int, int]
shared.init

shared[1] = 1
