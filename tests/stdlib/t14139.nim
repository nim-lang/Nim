import heapqueue

var test_queue : HeapQueue[int]

test_queue.push(7)
test_queue.push(3)
test_queue.push(9)
let i = test_queue.pushpop(10)
doAssert i == 3
