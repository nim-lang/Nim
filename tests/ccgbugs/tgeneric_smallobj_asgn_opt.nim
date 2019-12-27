discard """
  output: "done generic smallobj asgn opt"
"""

# bug #5402

import lists

type
  Container[T] = ref object
    obj: T

  ListOfContainers[T] = ref object
    list: DoublyLinkedList[Container[T]]

proc contains[T](this: ListOfContainers[T], obj: T): bool =
  for item in this.list.items():
    if item.obj == obj: return true
  return false

proc newListOfContainers[T](): ListOfContainers[T] =
  new(result)
  result.list = initDoublyLinkedList[Container[T]]()

let q = newListOfContainers[int64]()
if not q.contains(123):
  echo "done generic smallobj asgn opt"
