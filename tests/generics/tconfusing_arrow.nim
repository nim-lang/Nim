import algorithm, future

type Deck = object
  value: int

proc sort(h: var seq[Deck]) =
  # works:
  h.sort(proc (x, y: Deck): auto =
    cmp(x.value, y.value))
  # fails:
  h.sort((x, y: Deck) => cmp(ord(x.value), ord(y.value)))

var player: seq[Deck] = @[]

player.sort()
