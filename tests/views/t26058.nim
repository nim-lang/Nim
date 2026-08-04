{.experimental: "views".}

block: # bug #26058
  type
    Kind = enum
      kA, kB

    StateA = object
      x: int

    StateB = object
      y: string
      z: string

    Item = object
      cache: int
      case kind: Kind
      of kA:
        stateA: StateA
      of kB:
        stateB: StateB

  proc update(item: var Item) =
    case item.kind
    of kA:
      item.cache = item.stateA.x
    of kB:
      item.cache = item.stateB.y.len

  proc updateAll(items: var seq[var Item]): array[2, uint] =
    var i = 0
    for item in items.mitems:
      result[i] = cast[uint](item.addr)
      update(item)
      inc i

  var items = @[
    Item(kind: kA, stateA: StateA(x: 1)),
    Item(kind: kA, stateA: StateA(x: 2))
  ]

  let addresses = updateAll(items)
  doAssert addresses[1] - addresses[0] == sizeof(Item).uint
  doAssert items[0].cache == 1
  doAssert items[1].cache == 2
