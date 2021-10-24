# bug #18583
import std/deques
import std/heapqueue
import std/lists
import std/sets
from std/sequtils import toSeq

type
  Test = object

proc `$`(x: Test): string = ""

doAssert len([Test(), Test()].toDeque) == 2

proc `<`(x, y: Test): bool =
  len($x) < len($y)

doAssert len([Test(), Test()].toHeapQueue) == 2

doAssert len([Test(), Test()].toHashSet) == 1


doAssert len([Test(), Test()].toDoublyLinkedList.toSeq) == 2
doAssert len([Test(), Test()].toSinglyLinkedList.toSeq) == 2

