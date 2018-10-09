discard """
  output: '''true'''
"""

#bug #592

type
  ElementKind = enum inner, leaf
  TElement[TKey, TData] = object
    case kind: ElementKind
    of inner:
      key: TKey
      left, right: ref TElement[Tkey, TData]
    of leaf:
      data: TData
  PElement[TKey, TData] = ref TElement[TKey, TData]

proc newElement[Tkey, TData](other: PElement[TKey, TData]): PElement[Tkey, TData] =
  case other.kind:
  of inner:
    PElement[TKey, TData](kind: ElementKind.inner, key: other.key, left: other.left, right: other.right)
  of leaf:
    PElement[TKey, TData](kind: ElementKind.leaf, data: other.data)

proc newElement[TKey, TData](key: TKey, left: PElement[TKey, TData] = nil, right: PElement[TKey, TData] = nil) : PElement[TKey, TData] =
  PElement[TKey, TData](kind: ElementKind.inner, key: key, left: left, right: right)

proc newElement[Tkey, TData](key: Tkey, data: TData) : PElement[Tkey, TData] =
  PElement[TKey, TData](kind: ElementKind.leaf, data: data)

proc find*[TKey, TData](root: PElement[TKey, TData], key: TKey): TData {.raises: [KeyError].} =
  if root.left == nil:
    raise newException(KeyError, "key does not exist: " & key)

  var tmp_element = addr(root)

  while tmp_element.kind == inner and tmp_element.right != nil:
    tmp_element = if tmp_element.key > key:
                    addr(tmp_element.left)
                  else:
                    addr(tmp_element.right)

  if tmp_element.key == key:
    return tmp_element.left.data
  else:
    raise newException(KeyError, "key does not exist: " & key)

proc add*[TKey, TData](root: var PElement[TKey, TData], key: TKey, data: TData) : bool =
  if root.left == nil:
    root.key = key
    root.left = newElement[TKey, TData](key, data)
    return true

  var tmp_element = addr(root)

  while tmp_element.kind == ElementKind.inner and tmp_element.right != nil:
    tmp_element = if tmp_element.key > key:
                    addr(tmp_element.left)
                  else:
                    addr(tmp_element.right)

  if tmp_element.key == key:
    return false

  var old_element = newElement[TKey, TData](tmp_element[])
  var new_element = newElement[TKey, TData](key, data)

  tmp_element[] = if tmp_element.key < key:
                    newElement(key, old_element, new_element)
                  else:
                    newElement(tmp_element.key, new_element, old_element)

  return true

var tree = PElement[int, int](kind: ElementKind.inner, key: 0, left: nil, right: nil)
let result = add(tree, 1, 1)
echo(result)
