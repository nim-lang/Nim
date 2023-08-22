
type
  SharedPtr*[T] = object
    val: ptr tuple[atomicCounter: int, value: T]

proc `=destroy`*[T](p: var SharedPtr[T]) =
  mixin `=destroy`
  if p.val != nil:
    let c = atomicDec(p.val[].atomicCounter)
    if c == 0:
      `=destroy`(p.val.value)
      freeShared(p.val)
    p.val = nil

proc `=`*[T](dest: var SharedPtr[T], src: SharedPtr[T]) {.inline.} =
  if dest.val != src.val:
    if dest.val != nil:
      `=destroy`(dest)
    if src.val != nil:
      discard atomicInc(src.val[].atomicCounter)
    dest.val = src.val

proc newSharedPtr*[T](val: sink T): SharedPtr[T] =
  result.val = cast[type(result.val)](allocShared0(sizeof(result.val[])))
  result.val.atomicCounter = 1
  result.val.value = val

func get*[T](p: SharedPtr[T]): var T {.inline.} =
  p.val.value

func isNil*[T](p: SharedPtr[T]): bool {.inline.} =
  p.val == nil

proc cas*[T](p, old_val: var SharedPtr[T], new_val: SharedPtr[T]): bool {.inline.} =
  if old_val.val == new_val.val:
    result = true
  else:
    result = cas(p.val.addr, old_val.val, new_val.val)
    if result:
      `=destroy`(old_val)
      if new_val.val != nil:
        discard atomicInc(new_val.val[].atomicCounter)

