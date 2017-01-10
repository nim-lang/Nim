# bug #4589

import tables
type SimpleTable*[TKey, TVal] = TableRef[TKey, TVal]
template newSimpleTable*(TKey, TVal: typedesc): SimpleTable[TKey, TVal] = newTable[TKey, TVal]()
var fontCache : SimpleTable[string, SimpleTable[int32, int]]
fontCache = newSimpleTable(string, SimpleTable[int32, int])
