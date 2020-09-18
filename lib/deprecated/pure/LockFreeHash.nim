#nim c -t:-march=i686 --cpu:amd64 --threads:on -d:release lockfreehash.nim

import math, hashes

#------------------------------------------------------------------------------
## Memory Utility Functions

proc newHeap*[T](): ptr T =
  result = cast[ptr T](alloc0(sizeof(T)))

proc copyNew*[T](x: var T): ptr T =
  var
    size = sizeof(T)
    mem = alloc(size)
  copyMem(mem, x.addr, size)
  return cast[ptr T](mem)

proc copyTo*[T](val: var T, dest: int) =
  copyMem(pointer(dest), val.addr, sizeof(T))

proc allocType*[T](): pointer = alloc(sizeof(T))

proc newShared*[T](): ptr T =
  result = cast[ptr T](allocShared0(sizeof(T)))

proc copyShared*[T](x: var T): ptr T =
  var
    size = sizeof(T)
    mem = allocShared(size)
  copyMem(mem, x.addr, size)
  return cast[ptr T](mem)

#------------------------------------------------------------------------------
## Pointer arithmetic

proc `+`*(p: pointer, i: int): pointer {.inline.} =
  cast[pointer](cast[int](p) + i)

const
  minTableSize = 8
  reProbeLimit = 12
  minCopyWork = 4096
  intSize = sizeof(int)



when sizeof(int) == 4: # 32bit
  type
    Raw = range[0..1073741823]
    ## The range of uint values that can be stored directly in a value slot
    ## when on a 32 bit platform
elif sizeof(int) == 8: # 64bit
  type
    Raw = range[0'i64..4611686018427387903'i64]
    ## The range of uint values that can be stored directly in a value slot
    ## when on a 64 bit platform
else:
  {.error: "unsupported platform".}

type
  Entry = tuple
    key: int
    value: int

  EntryArr = ptr array[0..10_000_000, Entry]

  PConcTable[K, V] = ptr object {.pure.}
    len: int
    used: int
    active: int
    copyIdx: int
    copyDone: int
    next: PConcTable[K, V]
    data: EntryArr

proc setVal[K, V](table: var PConcTable[K, V], key: int, val: int,
  expVal: int, match: bool): int

#------------------------------------------------------------------------------

# Create a new table
proc newLFTable*[K, V](size: int = minTableSize): PConcTable[K, V] =
  let
    dataLen = max(nextPowerOfTwo(size), minTableSize)
    dataSize = dataLen*sizeof(Entry)
    dataMem = allocShared0(dataSize)
    tableSize = 7 * intSize
    tableMem = allocShared0(tableSize)
    table = cast[PConcTable[K, V]](tableMem)
  table.len = dataLen
  table.used = 0
  table.active = 0
  table.copyIdx = 0
  table.copyDone = 0
  table.next = nil
  table.data = cast[EntryArr](dataMem)
  result = table

#------------------------------------------------------------------------------

# Delete a table
proc deleteConcTable[K, V](tbl: PConcTable[K, V]) =
  deallocShared(tbl.data)
  deallocShared(tbl)

#------------------------------------------------------------------------------

proc `[]`[K, V](table: var PConcTable[K, V], i: int): var Entry {.inline.} =
  table.data[i]

#------------------------------------------------------------------------------
# State flags stored in ptr


proc pack[T](x: T): int {.inline.} =
  result = (cast[int](x) shl 2)
  #echo("packKey ",cast[int](x) , " -> ", result)

# Pop the flags off returning a 4 byte aligned ptr to our Key or Val
proc pop(x: int): int {.inline.} =
  result = x and 0xFFFFFFFC'i32

# Pop the raw value off of our Key or Val
proc popRaw(x: int): int {.inline.} =
  result = x shr 2

# Pop the flags off returning a 4 byte aligned ptr to our Key or Val
proc popPtr[V](x: int): ptr V {.inline.} =
  result = cast[ptr V](pop(x))
  #echo("popPtr " & $x & " -> " & $cast[int](result))

# Ghost (sentinel)
# K or V is no longer valid use new table
const Ghost = 0xFFFFFFFC
proc isGhost(x: int): bool {.inline.} =
  result = x == 0xFFFFFFFC

# Tombstone
# applied to V = K is dead
proc isTomb(x: int): bool {.inline.} =
  result = (x and 0x00000002) != 0

proc setTomb(x: int): int {.inline.} =
  result = x or 0x00000002

# Prime
# K or V is in new table copied from old
proc isPrime(x: int): bool {.inline.} =
  result = (x and 0x00000001) != 0

proc setPrime(x: int): int {.inline.} =
  result = x or 0x00000001

#------------------------------------------------------------------------------

##This is for i32 only need to override for i64
proc hashInt(x: int): int {.inline.} =
  var h = uint32(x) #shr 2'u32
  h = h xor (h shr 16'u32)
  h *= 0x85ebca6b'u32
  h = h xor (h shr 13'u32)
  h *= 0xc2b2ae35'u32
  h = h xor (h shr 16'u32)
  result = int(h)

#------------------------------------------------------------------------------

proc resize[K, V](self: PConcTable[K, V]): PConcTable[K, V] =
  var next = atomic_load_n(self.next.addr, ATOMIC_RELAXED)
  #echo("next = " & $cast[int](next))
  if next != nil:
    #echo("A new table already exists, copy in progress")
    return next
  var
    oldLen = atomic_load_n(self.len.addr, ATOMIC_RELAXED)
    newTable = newLFTable[K, V](oldLen*2)
    success = atomic_compare_exchange_n(self.next.addr, next.addr, newTable,
                  false, ATOMIC_RELAXED, ATOMIC_RELAXED)
  if not success:
    echo("someone beat us to it! delete table we just created and return his " &
        $cast[int](next))
    deleteConcTable(newTable)
    return next
  else:
    echo("Created New Table! " & $cast[int](newTable) & " Size = " & $newTable.len)
    return newTable


#------------------------------------------------------------------------------
#proc keyEQ[K](key1: ptr K, key2: ptr K): bool {.inline.} =
proc keyEQ[K](key1: int, key2: int): bool {.inline.} =
  result = false
  when K is Raw:
    if key1 == key2:
      result = true
  else:
    var
      p1 = popPtr[K](key1)
      p2 = popPtr[K](key2)
    if p1 != nil and p2 != nil:
      if cast[int](p1) == cast[int](p2):
        return true
      if p1[] == p2[]:
        return true

#------------------------------------------------------------------------------

#proc tableFull(self: var PConcTable[K,V]) : bool {.inline.} =


#------------------------------------------------------------------------------

proc copySlot[K, V](idx: int, oldTbl: var PConcTable[K, V],
    newTbl: var PConcTable[K, V]): bool =
  #echo("Copy idx " & $idx)
  var
    oldVal = 0
    oldkey = 0
    ok = false
  result = false
  #Block the key so no other threads waste time here
  while not ok:
    ok = atomic_compare_exchange_n(oldTbl[idx].key.addr, oldKey.addr,
      setTomb(oldKey), false, ATOMIC_RELAXED, ATOMIC_RELAXED)
  #echo("oldKey was = " & $oldKey & "  set it to tomb " & $setTomb(oldKey))
  #Prevent new values from appearing in the old table by priming
  oldVal = atomic_load_n(oldTbl[idx].value.addr, ATOMIC_RELAXED)
  while not isPrime(oldVal):
    var box = if oldVal == 0 or isTomb(oldVal): oldVal.setTomb.setPrime
      else: oldVal.setPrime
    if atomic_compare_exchange_n(oldTbl[idx].value.addr, oldVal.addr,
      box, false, ATOMIC_RELAXED, ATOMIC_RELAXED):
      if isPrime(box) and isTomb(box):
        return true
      oldVal = box
      break
  #echo("oldVal was = ", oldVal, "  set it to prime ", box)
  if isPrime(oldVal) and isTomb(oldVal):
    #when not (K is Raw):
    #  deallocShared(popPtr[K](oldKey))
    return false
  if isTomb(oldVal):
    echo("oldVal is Tomb!!!, should not happen")
  if pop(oldVal) != 0:
    result = setVal(newTbl, pop(oldKey), pop(oldVal), 0, true) == 0
  #if result:
    #echo("Copied a Slot! idx= " & $idx & " key= " & $oldKey & " val= " & $oldVal)
  #else:
    #echo("copy slot failed")
  # Our copy is done so we disable the old slot
  while not ok:
    ok = atomic_compare_exchange_n(oldTbl[idx].value.addr, oldVal.addr,
      oldVal.setTomb.setPrime, false, ATOMIC_RELAXED, ATOMIC_RELAXED)
  #echo("disabled old slot")
  #echo"---------------------"

#------------------------------------------------------------------------------

proc promote[K, V](table: var PConcTable[K, V]) =
  var
    newData = atomic_load_n(table.next.data.addr, ATOMIC_RELAXED)
    newLen = atomic_load_n(table.next.len.addr, ATOMIC_RELAXED)
    newUsed = atomic_load_n(table.next.used.addr, ATOMIC_RELAXED)

  deallocShared(table.data)
  atomic_store_n(table.data.addr, newData, ATOMIC_RELAXED)
  atomic_store_n(table.len.addr, newLen, ATOMIC_RELAXED)
  atomic_store_n(table.used.addr, newUsed, ATOMIC_RELAXED)
  atomic_store_n(table.copyIdx.addr, 0, ATOMIC_RELAXED)
  atomic_store_n(table.copyDone.addr, 0, ATOMIC_RELAXED)
  deallocShared(table.next)
  atomic_store_n(table.next.addr, nil, ATOMIC_RELAXED)
  echo("new table swapped!")

#------------------------------------------------------------------------------

proc checkAndPromote[K, V](table: var PConcTable[K, V], workDone: int): bool =
  var
    oldLen = atomic_load_n(table.len.addr, ATOMIC_RELAXED)
    copyDone = atomic_load_n(table.copyDone.addr, ATOMIC_RELAXED)
    ok: bool
  result = false
  if workDone > 0:
    #echo("len to copy =" & $oldLen)
    #echo("copyDone + workDone = " & $copyDone & " + " & $workDone)
    while not ok:
      ok = atomic_compare_exchange_n(table.copyDone.addr, copyDone.addr,
        copyDone + workDone, false, ATOMIC_RELAXED, ATOMIC_RELAXED)
    #if ok: echo("set copyDone")
    # If the copy is done we can promote this table
    if copyDone + workDone >= oldLen:
      # Swap new data
      #echo("work is done!")
      table.promote
      result = true

#------------------------------------------------------------------------------

proc copySlotAndCheck[K, V](table: var PConcTable[K, V], idx: int):
  PConcTable[K, V] =
  var
    newTable = cast[PConcTable[K, V]](atomic_load_n(table.next.addr,
        ATOMIC_RELAXED))
  result = newTable
  if newTable != nil and copySlot(idx, table, newTable):
    #echo("copied a single slot, idx = " & $idx)
    if checkAndPromote(table, 1): return table


#------------------------------------------------------------------------------

proc helpCopy[K, V](table: var PConcTable[K, V]): PConcTable[K, V] =
  var
    newTable = cast[PConcTable[K, V]](atomic_load_n(table.next.addr,
        ATOMIC_RELAXED))
  result = newTable
  if newTable != nil:
    var
      oldLen = atomic_load_n(table.len.addr, ATOMIC_RELAXED)
      copyDone = atomic_load_n(table.copyDone.addr, ATOMIC_RELAXED)
      copyIdx = 0
      work = min(oldLen, minCopyWork)
      #panicStart = -1
      workDone = 0
    if copyDone < oldLen:
      var ok: bool
      while not ok:
        ok = atomic_compare_exchange_n(table.copyIdx.addr, copyIdx.addr,
          copyIdx + work, false, ATOMIC_RELAXED, ATOMIC_RELAXED)
      #echo("copy idx = ", copyIdx)
      for i in 0..work-1:
        var idx = (copyIdx + i) and (oldLen - 1)
        if copySlot(idx, table, newTable):
          workDone += 1
      if workDone > 0:
        #echo("did work ", workDone, " on thread ", cast[int](myThreadID[pointer]()))
        if checkAndPromote(table, workDone): return table
    # In case a thread finished all the work then got stalled before promotion
    if checkAndPromote(table, 0): return table



#------------------------------------------------------------------------------

proc setVal[K, V](table: var PConcTable[K, V], key: int, val: int,
  expVal: int, match: bool): int =
  #echo("-try set- in table ", " key = ", (popPtr[K](key)[]), " val = ", val)
  when K is Raw:
    var idx = hashInt(key)
  else:
    var idx = popPtr[K](key)[].hash
  var
    nextTable: PConcTable[K, V]
    probes = 1
  # spin until we find a key slot or build and jump to next table
  while true:
    idx = idx and (table.len - 1)
    #echo("try set idx = " & $idx & "for" & $key)
    var
      probedKey = 0
      openKey = atomic_compare_exchange_n(table[idx].key.addr, probedKey.addr,
        key, false, ATOMIC_RELAXED, ATOMIC_RELAXED)
    if openKey:
      if val.isTomb:
        #echo("val was tomb, bail, no reason to set an open slot to tomb")
        return val
      #increment used slots
      #echo("found an open slot, total used = " &
      #$atomic_add_fetch(table.used.addr, 1, ATOMIC_RELAXED))
      discard atomic_add_fetch(table.used.addr, 1, ATOMIC_RELAXED)
      break # We found an open slot
    #echo("set idx ", idx, " key = ", key, " probed = ", probedKey)
    if keyEQ[K](probedKey, key):
      #echo("we found the matching slot")
      break # We found a matching slot
    if (not(expVal != 0 and match)) and (probes >= reProbeLimit or key.isTomb):
      if key.isTomb: echo("Key is Tombstone")
      #if probes >= reProbeLimit: echo("Too much probing " & $probes)
      #echo("try to resize")
      #create next bigger table
      nextTable = resize(table)
      #help do some copying
      #echo("help copy old table to new")
      nextTable = helpCopy(table)
      #now setVal in the new table instead
      #echo("jumping to next table to set val")
      return setVal(nextTable, key, val, expVal, match)
    else:
      idx += 1
      probes += 1
  # Done spinning for a new slot
  var oldVal = atomic_load_n(table[idx].value.addr, ATOMIC_RELAXED)
  if val == oldVal:
    #echo("this val is already in the slot")
    return oldVal
  nextTable = atomic_load_n(table.next.addr, ATOMIC_SEQ_CST)
  if nextTable == nil and
    ((oldVal == 0 and
    (probes >= reProbeLimit or table.used / table.len > 0.8)) or
    (isPrime(oldVal))):
    if table.used / table.len > 0.8: echo("resize because usage ratio = " &
      $(table.used / table.len))
    if isPrime(oldVal): echo("old val isPrime, should be a rare mem ordering event")
    nextTable = resize(table)
  if nextTable != nil:
    #echo("tomb old slot then set in new table")
    nextTable = copySlotAndCheck(table, idx)
    return setVal(nextTable, key, val, expVal, match)
  # Finally ready to add new val to table
  while true:
    if match and oldVal != expVal:
      #echo("set failed, no match  oldVal= " & $oldVal & " expVal= " & $expVal)
      return oldVal
    if atomic_compare_exchange_n(table[idx].value.addr, oldVal.addr,
        val, false, ATOMIC_RELEASE, ATOMIC_RELAXED):
      #echo("val set at table " & $cast[int](table))
      if expVal != 0:
        if (oldVal == 0 or isTomb(oldVal)) and not isTomb(val):
          discard atomic_add_fetch(table.active.addr, 1, ATOMIC_RELAXED)
        elif not (oldVal == 0 or isTomb(oldVal)) and isTomb(val):
          discard atomic_add_fetch(table.active.addr, -1, ATOMIC_RELAXED)
      if oldVal == 0 and expVal != 0:
        return setTomb(oldVal)
      else: return oldVal
    if isPrime(oldVal):
      nextTable = copySlotAndCheck(table, idx)
      return setVal(nextTable, key, val, expVal, match)

#------------------------------------------------------------------------------

proc getVal[K, V](table: var PConcTable[K, V], key: int): int =
  #echo("-try get-  key = " & $key)
  when K is Raw:
    var idx = hashInt(key)
  else:
    var idx = popPtr[K](key)[].hash
    #echo("get idx ", idx)
  var
    probes = 0
    val: int
  while true:
    idx = idx and (table.len - 1)
    var
      newTable: PConcTable[K, V] # = atomic_load_n(table.next.addr, ATOMIC_ACQUIRE)
      probedKey = atomic_load_n(table[idx].key.addr, ATOMIC_SEQ_CST)
    if keyEQ[K](probedKey, key):
      #echo("found key after ", probes+1)
      val = atomic_load_n(table[idx].value.addr, ATOMIC_ACQUIRE)
      if not isPrime(val):
        if isTomb(val):
          #echo("val was tomb but not prime")
          return 0
        else:
          #echo("-GotIt- idx = ", idx, " key = ", key, " val ", val )
          return val
      else:
        newTable = copySlotAndCheck(table, idx)
        return getVal(newTable, key)
    else:
      #echo("probe ", probes, " idx = ", idx, " key = ", key, " found ", probedKey )
      if probes >= reProbeLimit*4 or key.isTomb:
        if newTable == nil:
          #echo("too many probes and no new table ", key, "  ", idx )
          return 0
        else:
          newTable = helpCopy(table)
          return getVal(newTable, key)
      idx += 1
      probes += 1

#------------------------------------------------------------------------------

#proc set*(table: var PConcTable[Raw,Raw], key: Raw, val: Raw) =
#  discard setVal(table, pack(key), pack(key), 0, false)

#proc set*[V](table: var PConcTable[Raw,V], key: Raw, val: ptr V) =
#  discard setVal(table, pack(key), cast[int](val), 0, false)

proc set*[K, V](table: var PConcTable[K, V], key: var K, val: var V) =
  when not (K is Raw):
    var newKey = cast[int](copyShared(key))
  else:
    var newKey = pack(key)
  when not (V is Raw):
    var newVal = cast[int](copyShared(val))
  else:
    var newVal = pack(val)
  var oldPtr = pop(setVal(table, newKey, newVal, 0, false))
    #echo("oldPtr = ", cast[int](oldPtr), " newPtr = ", cast[int](newPtr))
  when not (V is Raw):
    if newVal != oldPtr and oldPtr != 0:
      deallocShared(cast[ptr V](oldPtr))



proc get*[K, V](table: var PConcTable[K, V], key: var K): V =
  when not (V is Raw):
    when not (K is Raw):
      return popPtr[V](getVal(table, cast[int](key.addr)))[]
    else:
      return popPtr[V](getVal(table, pack(key)))[]
  else:
    when not (K is Raw):
      return popRaw(getVal(table, cast[int](key.addr)))
    else:
      return popRaw(getVal(table, pack(key)))











#proc `[]`[K,V](table: var PConcTable[K,V], key: K): PEntry[K,V] {.inline.} =
#  getVal(table, key)

#proc `[]=`[K,V](table: var PConcTable[K,V], key: K, val: V): PEntry[K,V] {.inline.} =
#  setVal(table, key, val)






#Tests ----------------------------
when not defined(testing) and isMainModule:
  import locks, times, mersenne

  const
    numTests = 100000
    numThreads = 10



  type
    TestObj = tuple
      thr: int
      f0: int
      f1: int

    Data = tuple[k: string, v: TestObj]
    PDataArr = array[0..numTests-1, Data]
    Dict = PConcTable[string, TestObj]

  var
    thr: array[0..numThreads-1, Thread[Dict]]

    table = newLFTable[string, TestObj](8)
    rand = newMersenneTwister(2525)

  proc createSampleData(len: int): PDataArr =
    #result = cast[PDataArr](allocShared0(sizeof(Data)*numTests))
    for i in 0..len-1:
      result[i].k = "mark" & $(i+1)
      #echo("mark" & $(i+1), " ", hash("mark" & $(i+1)))
      result[i].v.thr = 0
      result[i].v.f0 = i+1
      result[i].v.f1 = 0
      #echo("key = " & $(i+1) & " Val ptr = " & $cast[int](result[i].v.addr))



  proc threadProc(tp: Dict) {.thread.} =
    var t = cpuTime();
    for i in 1..numTests:
      var key = "mark" & $(i)
      var got = table.get(key)
      got.thr = cast[int](myThreadID[pointer]())
      got.f1 = got.f1 + 1
      table.set(key, got)
    t = cpuTime() - t
    echo t


  var testData = createSampleData(numTests)

  for i in 0..numTests-1:
    table.set(testData[i].k, testData[i].v)

  var i = 0
  while i < numThreads:
    createThread(thr[i], threadProc, table)
    i += 1

  joinThreads(thr)





  var fails = 0

  for i in 0..numTests-1:
    var got = table.get(testData[i].k)
    if got.f0 != i+1 or got.f1 != numThreads:
      fails += 1
      echo(got)

  echo("Failed read or write = ", fails)


  #for i in 1..numTests:
  #  echo(i, " = ", hashInt(i) and 8191)

  deleteConcTable(table)
